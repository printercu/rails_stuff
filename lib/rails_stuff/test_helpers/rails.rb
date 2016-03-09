require 'action_dispatch'
require 'rails_stuff/test_helpers/response'

ActionDispatch::TestResponse.class_eval do
  include RailsStuff::TestHelpers::Response
end

require 'rails_stuff/test_helpers/concurrency'
require 'rails_stuff/test_helpers/configurator'
