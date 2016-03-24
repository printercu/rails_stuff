require 'rails_helper'
require 'rails/engine'
require 'rails/railtie'
require 'support/active_record'
require 'kaminari'
require 'has_scope'
Kaminari::Hooks.init

# # Routes
TestRoutes = ActionDispatch::Routing::RouteSet.new
TestRoutes.draw do
  namespace :site do
    resources :users do
      resources :projects, only: [:index, :create, :update], shallow: true
    end
  end
end

# Make rspec-rails to work without full rails app.
application = OpenStruct.new(
  routes: TestRoutes,
  env_config: {},
  config: OpenStruct.new(root: GEM_ROOT.join('spec/support')),
)
Rails.define_singleton_method(:application) { application }

# # Models
module BuildDefault
  def build_default(**attrs)
    new(const_get(:DEFAULT_ATTRS).merge(attrs))
  end

  def create_default!(**attrs)
    build_default(attrs).tap(&:save)
  end
end

class User < ActiveRecord::Base
  has_many :projects
  validates_presence_of :name, :email
  scope :by_email, ->(val) { where(email: val) }

  DEFAULT_ATTRS = {
    name: 'John',
    email: 'john@example.domain',
  }.freeze
  extend BuildDefault
end

class Project < ActiveRecord::Base
  belongs_to :user, required: true
  validates_presence_of :name
  extend RailsStuff::TypesTracker

  DEFAULT_ATTRS = {
    name: 'Haps.me',
    type: 'Project::External',
  }.freeze
  extend BuildDefault

  class Internal < self
  end

  class External < self
  end

  class Hidden < self
    unregister_type
  end
end

# # Controllers
class ApplicationController < ActionController::Base
  extend RailsStuff::ResourcesController
  include TestRoutes.url_helpers
  self.view_paths = GEM_ROOT.join('spec/support/app/views')
end

class SiteController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }
end

module Site
  class UsersController < SiteController
    resources_controller kaminari: true
    permit_attrs :name, :email
    has_scope :by_email
  end

  class ProjectsController < SiteController
    resources_controller sti: true, kaminari: true
    resource_helper :user
    permit_attrs :name
    permit_attrs_for Project::External, :company
    permit_attrs_for Project::Internal, :department

    def create
      super(action: :index)
    end

    protected

    def after_save_url
      url_for action: :index, user_id: resource.user_id
    end

    def source_relation
      params.key?(:user_id) ? user.projects : self.class.resource_class
    end
  end
end
