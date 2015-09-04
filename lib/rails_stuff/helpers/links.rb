module RailsStuff
  module Helpers
    # Link helpers for basic actions.
    module Links
      ICONS = {
        destroy:  -> { translate_action(:destroy) },
        edit:     -> { translate_action(:edit) },
        new:      -> { translate_action(:new) },
      }

      def basic_link_icons
        ICONS
      end

      def basic_link_icon(action)
        val = basic_link_icons[action]
        val.is_a?(Proc) ? instance_exec(&val) : val
      end

      def link_to_destroy(url, **options)
        link_to basic_link_icon(:destroy), url, {
          title: translate_action(:delete),
          method: :delete,
          data:   {confirm: translate_confirmation(:delete)},
        }.merge!(options)
      end

      def link_to_edit(url = nil, **options)
        link_to basic_link_icon(:edit), (url || url_for(action: :edit)),
          {title: translate_action(:edit)}.merge!(options)
      end

      def link_to_new(url = nil, **options)
        link_to basic_link_icon(:new), (url || url_for(action: :new)), options
      end
    end
  end
end
