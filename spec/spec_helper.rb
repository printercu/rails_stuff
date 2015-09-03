$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'rspec/its'
require 'active_support/core_ext/time'
require 'json'

Time.zone_default = Time.find_zone('UTC')

require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
require 'support/schema'

require 'rails_stuff'
