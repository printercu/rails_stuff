require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/transform_values'

module RailsStuff
  module Helpers
    module Bootstrap
      BOOTSTRAP_FLASH_TYPE = {
        success:  'alert-success',
        error:    'alert-danger',
        alert:    'alert-warning',
        notice:   'alert-info',
      }.stringify_keys.freeze

      def flash_messages
        flash.map do |type, message|
          content_tag :div, class: [:alert, BOOTSTRAP_FLASH_TYPE[type] || type] do
            content_tag(:button, '&times;'.html_safe, class: :close, data: {dismiss: :alert}) +
              simple_format(message)
          end
        end.join.html_safe
      end

      ICONS = {
        destroy:  %(<span class='glyphicon icon-destroy'></span>),
        edit:     %(<span class='glyphicon icon-edit'></span>),
        new:      %(<span class='glyphicon icon-add'></span>),
      }.tap { |x| x.transform_values!(&:html_safe) if ''.respond_to?(:html_safe) }

      def basic_link_icons
        ICONS
      end
    end
  end
end
