module RailsStuff
  module Statusable
    # Basic builder for statuses list. Generates methods and scopes.
    class Builder
      attr_reader :helper, :options, :prefix, :suffix
      delegate :model, :field, :list, to: :helper
      delegate :define_scope, :define_method, :define_class_method, to: :helper

      def initialize(helper, **options)
        @helper = helper
        @options = options
        @prefix = options[:prefix]
        @suffix = options[:suffix]
      end

      def generate
        validations if options.fetch(:validate, true)
        field_accessor
        field_scope
        value_scopes
        value_accessors
        translation_helpers
      end

      def validations
        model.validates_inclusion_of field,
          {in: valid_list}.merge!(options.fetch(:validate, {}))
      end

      # Field reader returns string, so we stringify list for validation.
      def valid_list
        list.map(&:to_s)
      end

      # Yields every status with it's database value into block.
      def each_status
        list.each { |x| yield x, x.to_s }
      end

      # Wraps status name with prefix and suffix.
      def status_method_name(status)
        "#{prefix}#{status}#{suffix}"
      end

      # Scope with given status. Useful for has_scope.
      def field_scope
        field = self.field
        define_scope "with_#{field}", ->(status) { where(field => status) }
      end

      # Status accessors for every status.
      def value_accessors
        each_status do |status, value|
          value_accessor status, value
        end
      end

      # Scopes for every status.
      def value_scopes
        field = self.field
        each_status do |status, value|
          define_scope status_method_name(status), -> { where(field => value) }
          define_scope "not_#{status_method_name(status)}", -> { where.not(field => value) }
        end
      end

      # Generates methods for specific value.
      def value_accessor(status, value)
        field = self.field

        # Shortcut to check status.
        define_method "#{status_method_name(status)}?" do
          # Access raw value, 'cause reader can be overriden.
          self[field] == value
        end

        # Shortcut to update status.
        define_method "#{status_method_name(status)}!" do
          update!(field => value)
        end
      end

      def field_accessor
        field_reader
        field_writer
      end

      # Make field accept sympbols.
      def field_writer
        define_method "#{field}=" do |val|
          val = val.to_s if val.is_a?(Symbol)
          super(val)
        end
      end

      # Status as symbol.
      def field_reader
        field = self.field
        define_method "#{field}_sym" do
          val = self[field]
          val && val.to_sym
        end
      end

      def translation_helpers
        field = self.field
        define_method "#{field}_name" do
          val = send(field)
          self.class.t(".#{field}_name.#{val}") if val
        end
      end
    end
  end
end
