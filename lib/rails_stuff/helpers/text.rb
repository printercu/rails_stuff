module RailsStuff
  module Helpers
    module Text
      # Replaces blank values with cached placeholder from translations.
      # When called with block, it'll check value for blankness, but returns
      # block's result if value is present.
      #
      #     replace_blank(description)
      #     replace_blank(tags) { tags.join(', ') }
      #     replace_blank(order.paid_at) { |x| l x, format: :long }
      #
      def replace_blank(value, &block)
        if value.blank?
          blank_placeholder
        else
          block_given? ? capture(value, &block) : value
        end
      end

      # Default placeholder value.
      def blank_placeholder
        @_blank_placeholder ||= content_tag :small,
          "(#{I18n.t(:'helpers.placeholder.blank', default: '-')})",
          class: :'text-muted'
      end
    end
  end
end
