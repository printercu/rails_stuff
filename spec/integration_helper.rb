require 'rails_helper'
require 'rails/engine'
require 'rails/railtie'
require 'support/active_record'
require 'kaminari'
require 'has_scope'
require 'activemodel_translation/helper'
Kaminari::Hooks.init

ENV['RAILS_ENV'] = 'test'
class TestApplication < Rails::Application
  config.eager_load = false
  config.log_level = :debug
  secrets[:secret_key_base] = 'test'

  config.action_dispatch.rescue_responses.merge!(
    'RailsStuff::ResourcesController::StiHelpers::InvalidType' => :unprocessable_entity,
  )
end
Rails.application.initialize!

# # Routes
Rails.application.routes.draw do
  namespace :site do
    resources :users do
      resources :projects, shallow: true
    end
    resources :forms, only: :index
  end
end

RailsStuff::TestHelpers.setup only: %w(integration_session response)
RailsStuff::RSpecHelpers.setup only: %w(groups/request clear_logs)

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

class Customer < ActiveRecord::Base
  extend ActiveModel::Translation
  extend RailsStuff::Statusable
  has_status_field :status, [:verified, :banned, :premium]
end

class Order < ActiveRecord::Base
  extend ActiveModel::Translation
  extend RailsStuff::Statusable
  has_status_field :status, mapping: {pending: 1, accepted: 2, delivered: 3}
end

# # Controllers
class ApplicationController < ActionController::Base
  extend RailsStuff::ResourcesController
  include Rails.application.routes.url_helpers
  self.view_paths = GEM_ROOT.join('spec/support/app/views')
end

class SiteController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }
  respond_to :html
end

module Site
  class UsersController < SiteController
    resources_controller kaminari: true
    permit_attrs :name, :email
    has_scope :by_email
  end

  class ProjectsController < SiteController
    resources_controller  sti: true,
                          kaminari: true,
                          belongs_to: [:user, optional: true]
    permit_attrs :name
    permit_attrs_for Project::External, :company
    permit_attrs_for Project::Internal, :department

    def create
      super(action: :index)
    end
  end

  class FormsController < SiteController
  end
end
