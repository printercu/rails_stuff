require 'action_view'
require 'action_dispatch'
require 'action_controller'
require 'rspec/rails'
require 'support/controller'

ActionDispatch::TestResponse.class_eval do
  # Makes it easier to debug failed specs.
  def inspect
    "<Response(#{status})>"
  end
end
