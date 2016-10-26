module RailsStuff
  module Statusable
    # Generates methods and scopes when status names are mapped to internal values.
    class MappedBuilder < Statusable::Builder
      delegate :mapping, :inverse_mapping, to: :helper

      # Field reader returns mapped value, so we don't need to stringify list.
      alias_method :valid_list, :list

      # Scope with given status. Useful for has_scope.
      def field_scope
        field = self.field
        helper = self.helper
        define_scope "with_#{field}", ->(status) { where(field => helper.map(status)) }
      end

      def value_methods
        field = self.field
        mapping.stringify_keys.each do |status, value|
          define_scope "#{prefix}#{status}#{suffix}", -> { where(field => value) }
          define_scope "not_#{prefix}#{status}#{suffix}", -> { where.not(field => value) }
          status_accessor status, value
        end
      end

      def field_reader
        field = self.field
        helper = self.helper

        # Returns status name.
        define_method field do |original = false|
          val = super()
          original || !val ? val : helper.unmap(val)
        end

        # Status as symbol.
        define_method "#{field}_sym" do
          val = public_send(field)
          val && val.to_sym
        end
      end

      def field_writer
        helper = self.helper
        # Make field accept sympbols.
        define_method "#{field}=" do |val|
          val = val.to_s if val.is_a?(Symbol)
          super(helper.map(val))
        end
      end
    end
  end
end
