module RailsStuff
  module Helpers
    module Translation
      class << self
        def i18n_raise
          @i18n_raise ||= defined?(Rails) && ActionView::Base.raise_on_missing_translations
        end

        attr_writer :i18n_raise
      end

      # Translates & caches actions within `helpers.actions` scope.
      def translate_action(action)
        @translate_action ||= Hash.new do |h, key|
          h[key] = I18n.t("helpers.actions.#{key}", raise: Translation.i18n_raise)
        end
        @translate_action[action]
      end

      # Translates & caches confirmations within `helpers.confirmations` scope.
      def translate_confirmation(action)
        @translate_confirmation ||= Hash.new do |h, key|
          h[key] = I18n.t("helpers.confirmations.#{key}",
            default: [:'helpers.confirm'],
            raise: Translation.i18n_raise,
          )
        end
        @translate_confirmation[action]
      end

      # Translates boolean values.
      def yes_no(val)
        @translate_yes_no ||= Hash.new do |h, key|
          h[key] = I18n.t("helpers.yes_no.#{key}", raise: Translation.i18n_raise)
        end
        @translate_yes_no[val.to_s]
      end
    end
  end
end
