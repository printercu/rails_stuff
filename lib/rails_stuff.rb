require 'rails_stuff/version'
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
  autoload :SortScope
  autoload :Statusable
  autoload :TypesTracker
end

require 'rails_stuff/engine' if defined?(Rails::Engine)
