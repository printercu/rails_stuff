require 'responders'

module RailsStuff
  # InheritedResources on diet.
  # Tiny and simple implementation. Feel free to change/extend it right in you
  # application. Or just use separate modules.
  module ResourcesController
    extend ActiveSupport::Autoload

    class << self
      delegate :kaminari!, to: 'RailsStuff::ResourcesController::BasicHelpers'
    end

    autoload :Actions
    autoload :BasicHelpers
    autoload :Responder
    autoload :StiHelpers
    autoload :ResourceHelper

    # Setups basic actions and helpers in resources controller.
    #
    # #### Options
    #
    # - `sti` - include STI helpers
    # - `after_save_action` - action to use for `after_save_url`
    # - `source_relation` - override `source_relation`
    def resources_controller(**options)
      include BasicHelpers
      include StiHelpers if options[:sti]
      include Actions
      extend ResourceHelper

      respond_to :html
      self.responder = Responder
      self.after_save_action = options[:after_save_action] || after_save_action

      if options[:source_relation] # rubocop:disable GuardClause
        protected define_method(:source_relation, &options[:source_relation])
      end
    end
  end
end
