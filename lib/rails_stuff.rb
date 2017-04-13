require 'rails_stuff/version'
require 'active_support/version'
require 'active_support/dependencies/autoload'

# Useful stuff for Rails.
module RailsStuff
  extend ActiveSupport::Autoload

  autoload :Helpers
  autoload :AssociationWriter
  autoload :NullifyBlankAttrs
  autoload :ParamsParser
  autoload :RandomUniqAttr
  autoload :RedisStorage
  autoload :RequireNested
  autoload :ResourcesController
  autoload :Responders
  autoload :RSpecHelpers, 'rails_stuff/rspec_helpers'
  autoload :SortScope
  autoload :Statusable
  autoload :TestHelpers, 'rails_stuff/test_helpers'
  autoload :TypesTracker

  module_function

  def rails_version
    @rails_version = ActiveSupport::VERSION
  end

  def rails4?
    rails_version::MAJOR == 4
  end
end

require 'rails_stuff/engine' if defined?(Rails::Engine)
