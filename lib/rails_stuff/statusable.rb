module RailsStuff
  # Basic helpers to work with `status` field.
  #
  # For every status value it provides:
  #
  # - scope with the same name (eg. `.rejected`)
  # - inquiry method to check status (eg. `#rejected?`)
  # - bang method to update status (eg. `#rejected!`)
  #
  # It also contains translation helpers, validator, and `#status=` setter
  # with symbols support.
  module Statusable
    # Defines all helpers working with specific field (default to `status`).
    # List of values can be given as second argument, otherwise it'll
    # be read from const with pluralized name of field (eg. default to STATUSES).
    def has_status_field(field = :status, statuses = nil, **options) # rubocop:disable AbcSize
      statuses ||= const_get(field.to_s.pluralize.upcase)
      prefix = options[:prefix]

      if options[:validate] != false
        validates_inclusion_of field,
          {in: statuses.map(&:to_s)}.merge!(options.fetch(:validate, {}))
      end

      statusable_methods.generate_field_methods field, statuses

      # Scope with given status. Useful for has_scope.
      scope "with_#{field}", ->(status) { where(field => status) }

      statuses.map(&:to_s).each do |status_name|
        # Scopes for every status.
        scope "#{prefix}#{status_name}", -> { where(field => status_name) }
        scope "not_#{prefix}#{status_name}", -> { where.not(field => status_name) }
        statusable_methods.status_accessor field, status_name, prefix
      end
    end

    # Module to hold generated methods.
    def statusable_methods
      # Include generated methods with a module, not right in class.
      @statusable_methods ||= Module.new.tap do |m|
        m.const_set :ClassMethods, Module.new
        m.extend MethodsGenerator
        include m
        extend m::ClassMethods
      end
    end

    # Generates methods.
    module MethodsGenerator
      def generate_field_methods(field, statuses)
        field_accessor field
        translation_helpers field
        select_options_helper field, statuses
      end

      def status_accessor(field, status_name, prefix = nil)
        # Shortcut to check status.
        define_method "#{prefix}#{status_name}?" do
          self[field] == status_name
        end

        # Shortcut to update status.
        define_method "#{prefix}#{status_name}!" do
          update_attributes!(field => status_name)
        end
      end

      def field_accessor(field)
        # Make field accept sympbols.
        define_method "#{field}=" do |val|
          val = val.to_s if val.is_a?(Symbol)
          super(val)
        end

        # Status as symbol.
        define_method "#{field}_sym" do
          val = self[field]
          val && val.to_sym
        end
      end

      def translation_helpers(field)
        # Class-level translation helper.
        generate_class_method "#{field}_name" do |status|
          t(".#{field}_name.#{status}") if status
        end

        # Translation helper.
        define_method "#{field}_name" do
          val = send field
          self.class.t(".#{field}_name.#{val}") if val
        end
      end

      def select_options_helper(field, statuses)
        translation_method = :"#{field}_name"
        # Returns array compatible with select_options helper.
        generate_class_method "#{field}_select_options" do |args = {}|
          filtered_statuses = statuses - Array.wrap(args[:except])
          filtered_statuses.map { |x| [send(translation_method, x), x] }
        end
      end

      def generate_class_method(method, &block)
        const_get(:ClassMethods).send(:define_method, method, &block)
      end
    end
  end
end
