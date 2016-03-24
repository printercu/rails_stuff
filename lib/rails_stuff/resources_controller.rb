require 'responders'

module RailsStuff
  # InheritedResources on diet.
  # Tiny and simple implementation. Feel free to change/extend it right in you
  # application. Or just use separate modules.
  module ResourcesController
    extend ActiveSupport::Autoload

    autoload :Actions
    autoload :BasicHelpers
    autoload :HasScopeHelpers
    autoload :KaminariHelpers
    autoload :ResourceHelper
    autoload :Responder
    autoload :StiHelpers

    extend KaminariHelpers::ConfigMethods

    class << self
      def inject(base, **options)
        base.include BasicHelpers
        base.include KaminariHelpers if options.fetch(:kaminari) { use_kaminari? }
        base.include StiHelpers if options[:sti]
        base.include Actions
        base.extend HasScopeHelpers
        base.extend ResourceHelper
      end
    end

    # Setups basic actions and helpers in resources controller.
    #
    # #### Options
    #
    # - `sti` - include STI helpers
    # - `kaminari` - include Kaminari helpers
    # - `after_save_action` - action to use for `after_save_url`
    # - `source_relation` - override `source_relation`
    def resources_controller(**options)
      ResourcesController.inject(self, **options)

      respond_to :html
      self.responder = Responder
      self.after_save_action = options[:after_save_action] || after_save_action

      if options[:source_relation]
        protected define_method(:source_relation, &options[:source_relation])
      end
    end
  end
end
