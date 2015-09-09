require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
require 'support/schema'

require 'database_cleaner'
RSpec.configure do |config|
  config.around db_cleaner: true do |ex|
    DatabaseCleaner.cleaning { ex.run }
  end
end
