require 'rails_stuff/version'
require 'active_support/dependencies/autoload'

# Useful stuff for Rails.
module RailsStuff
  extend ActiveSupport::Autoload

  autoload :Helpers
  autoload :NullifyBlankAttrs
  autoload :ParamsParser
  autoload :RandomUniqAttr
  autoload :RedisStorage
  autoload :ResourcesController
  autoload :Statusable
  autoload :SortScope
  autoload :TypesTracker
end

require 'rails_stuff/engine' if defined?(Rails::Engine)
