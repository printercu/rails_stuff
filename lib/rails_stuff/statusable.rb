module RailsStuff
  # Basic helpers to work with `status`-like field.
  #
  # For every status value it provides:
  #
  # - scopes with status name (eg. `.rejected`, '.not_rejected')
  # - inquiry method to check status (eg. `#rejected?`)
  # - bang method to update status (eg. `#rejected!`)
  #
  # It also provides:
  #
  # - translation helpers (`acttivemodel_translation` gem required)
  # - inclusion validator
  # - string/symbol agnostic `#status=`
  # - `#status_sym`
  # - `status_select_options` helper.
  #
  # It supports mapped statuses, just provide a hash with
  # `{status_name => interna_value}` instead of array of statuses.
  module Statusable
    # Defines all helpers working with `field` (default to `status`).
    # List of values can be given as second argument, otherwise it'll
    # be read from consts using pluralized name of `field`
    # (eg. default to `STATUSES_MAPPING`, `STATUSES`).
    #
    # #### Options
    #
    # - `prefix`    - used to prefix value-named helpers.
    #
    #         # this defines #shipped?, #shipped! methods
    #         has_status_field :delivery_status, %i(shipped delivered)
    #
    #         # this defines #delivery_shipped?, #delivery_shipped! methods
    #         has_status_field :delivery_status, %i(shipped delivered), prefix: :delivery
    #
    # - `validate`  - additional options for validatior. `false` to disable it.
    def has_status_field(field = :status, statuses = nil, **options)
      unless statuses
        const_name = "#{field.to_s.pluralize.upcase}_MAPPING"
        const_name = field.to_s.pluralize.upcase unless const_defined?(const_name)
        statuses = const_get(const_name)
      end
      generator = statuses.is_a?(Hash) ? MappedBuilder : Builder
      generator.new(self, field, statuses, options).generate
    end

    # Module to hold generated methods.
    def statusable_methods
      # Include generated methods with a module, not right in class.
      @statusable_methods ||= Module.new.tap do |m|
        m.const_set :ClassMethods, Module.new
        include m
        extend m::ClassMethods
      end
    end

    # Generates methods and scopes.
    class Builder
      attr_reader :model, :field, :statuses, :options, :prefix
      alias_method :statuses_list, :statuses

      def initialize(model, field, statuses, **options)
        @model = model
        @field = field
        @statuses = statuses
        @options = options
        @prefix = options[:prefix]
      end

      def generate
        validations unless options[:validate] == false
        field_reader
        field_writer
        select_options_helper
        translation_helpers
        field_scope
        value_methods
      end

      def validations
        model.validates_inclusion_of field,
          {in: statuses.map(&:to_s)}.merge!(options.fetch(:validate, {}))
      end

      # Scope with given status. Useful for has_scope.
      def field_scope
        field = self.field
        model.scope "with_#{field}", ->(status) { where(field => status) }
      end

      def value_methods
        field = self.field
        statuses.map(&:to_s).each do |status_name|
          # Scopes for every status.
          model.scope "#{prefix}#{status_name}", -> { where(field => status_name) }
          model.scope "not_#{prefix}#{status_name}", -> { where.not(field => status_name) }
          status_accessor field, status_name, status_name, prefix
        end
      end

      # Generates methods for specific value.
      def status_accessor(field, status_name, value, prefix = nil)
        # Shortcut to check status.
        define_method "#{prefix}#{status_name}?" do
          self[field] == value
        end

        # Shortcut to update status.
        define_method "#{prefix}#{status_name}!" do
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
          val = send(field)
          val && val.to_sym
        end
      end

      def translation_helpers
        field = self.field
        sym_method = "#{field}_sym"

        # Class-level translation helper.
        generate_class_method "#{field}_name" do |status|
          t(".#{field}_name.#{status}") if status
        end

        # Translation helper.
        define_method "#{field}_name" do
          val = send(sym_method)
          self.class.t(".#{field}_name.#{val}") if val
        end
      end

      def select_options_helper
        statuses_list = self.statuses_list
        translation_method = :"#{field}_name"
        # Returns array compatible with select_options helper.
        generate_class_method "#{field}_select_options" do |args = {}|
          filtered_statuses = statuses_list - Array.wrap(args[:except])
          filtered_statuses.map { |x| [send(translation_method, x), x] }
        end
      end

      def define_method(method, &block)
        model.statusable_methods.send(:define_method, method, &block)
      end

      def generate_class_method(method, &block)
        model.statusable_methods::ClassMethods.send(:define_method, method, &block)
      end
    end

    # Generates methods and scopes when status names are mapped to internal values.
    class MappedBuilder < Builder
      attr_reader :mapping, :statuses_list

      def initialize(*)
        super
        @mapping = statuses.with_indifferent_access
        @statuses_list = statuses.keys
      end

      def validations
        model.validates_inclusion_of field,
          {in: statuses.values}.merge!(options.fetch(:validate, {}))
      end

      # Scope with given status. Useful for has_scope.
      def field_scope
        field = self.field
        mapping = self.mapping
        model.scope "with_#{field}", ->(status) do
          values = Array[status].map { |x| mapping.fetch(x, x) }
          where(field => values)
        end
      end

      def value_methods
        field = self.field
        statuses.each do |status_name, value|
          # Scopes for every status.
          model.scope "#{prefix}#{status_name}", -> { where(field => value) }
          model.scope "not_#{prefix}#{status_name}", -> { where.not(field => value) }
          status_accessor field, status_name, value, prefix
        end
      end

      def field_reader
        field = self.field
        inverse_mapping = statuses.stringify_keys.invert

        # Returns status name.
        define_method field do |mapped = false|
          val = super()
          return val unless mapped && val
          mapped = inverse_mapping[val]
          raise "Missing mapping for value #{val.inspect}" unless mapped
          mapped
        end

        # Status as symbol.
        define_method "#{field}_sym" do
          val = public_send(field, true)
          val && val.to_sym
        end
      end

      def field_writer
        mapping = self.mapping
        # Make field accept sympbols.
        define_method "#{field}=" do |val|
          val = val.to_s if val.is_a?(Symbol)
          super(mapping.fetch(val, val))
        end
      end
    end
  end
end
