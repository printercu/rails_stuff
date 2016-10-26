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
        field_reader
        field_writer
        translation_helpers
        field_scope
        value_methods
      end

      def validations
        model.validates_inclusion_of field,
          {in: valid_list}.merge!(options.fetch(:validate, {}))
      end

      # Field reader returns string, so we stringify list for validation.
      def valid_list
        list.map(&:to_s)
      end

      # Scope with given status. Useful for has_scope.
      def field_scope
        field = self.field
        define_scope "with_#{field}", ->(status) { where(field => status) }
      end

      # Scopes for every status and status accessors.
      def value_methods
        field = self.field
        list.map(&:to_s).each do |status|
          define_scope "#{prefix}#{status}#{suffix}", -> { where(field => status) }
          define_scope "not_#{prefix}#{status}#{suffix}", -> { where.not(field => status) }
          status_accessor status, status
        end
      end

      # Generates methods for specific value.
      def status_accessor(status, value)
        field = self.field

        # Shortcut to check status.
        define_method "#{prefix}#{status}#{suffix}?" do
          # Access raw value, 'cause reader can be overriden.
          self[field] == value
        end

        # Shortcut to update status.
        define_method "#{prefix}#{status}#{suffix}!" do
          update_attributes!(field => value)
        end
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
