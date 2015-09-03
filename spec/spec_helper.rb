$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec/its'
require 'active_support/core_ext/time'

Time.zone_default = Time.find_zone('UTC')

require 'rails_stuff'
