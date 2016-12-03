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
    autoload :Helper, 'rails_stuff/statusable/helper'
    autoload :Builder, 'rails_stuff/statusable/builder'
    autoload :MappedHelper, 'rails_stuff/statusable/mapped_helper'
    autoload :MappedBuilder, 'rails_stuff/statusable/mapped_builder'

    class << self
      # Fetches statuses list from model constants. See #has_status_field.
      def fetch_statuses(model, field)
        const_name = "#{field.to_s.pluralize.upcase}_MAPPING"
        const_name = field.to_s.pluralize.upcase unless model.const_defined?(const_name)
        model.const_get(const_name)
      end
    end

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
    #         has_status_field :delivery_status, %i(shipped delivered), prefix: :delivery_
    #
    # - `suffix`    - similar to `prefix`.
    #
    # - `validate`  - additional options for validatior. `false` to disable it.
    #
    # - `helper`    - custom helper class.
    #
    # - `builder`   - custom methods builder class.
    #
    # - `mapping`   - shortcut for `statuses` param (see examples).
    #
    # Pass block to customize methods generation process (see Builder for available methods):
    #
    #   # This will define only scope with status names, but no other methods.
    #   has_status_field do |builder|
    #     builder.value_scopes
    #   end
    #
    # Examples:
    #
    #   # Setup #status field, take list from STATUSES or STATUSES_MAPPING constant.
    #   has_status_field
    #   # Custom field, take kist from KINDS or KINDS_MAPPING:
    #   has_status_field :kind
    #   # Inline statuses list and options:
    #   has_status_field :status, %i(one two), prefix: :my_
    #   has_status_field :status, {one: 1, two: 2}, prefix: :my_
    #   has_status_field :status, mapping: {one: 1, two: 2}, prefix: :my_
    #   # Mapped field without options:
    #   has_status_field :status, {one: 1, two: 2}, {}
    #   has_status_field :status, mapping: {one: 1, two: 2}
    #
    def has_status_field(field = :status, statuses = nil, mapping: nil, **options)
      statuses ||= mapping || Statusable.fetch_statuses(self, field)
      is_mapped = statuses.is_a?(Hash)
      helper_class = options.fetch(:helper) { is_mapped ? MappedHelper : Helper }
      helper = helper_class.new(self, field, statuses)
      helper.attach
      builder_class = options.fetch(:builder) { is_mapped ? MappedBuilder : Builder }
      if builder_class
        builder = builder_class.new(helper, options)
        block_given? ? yield(builder) : builder.generate
      end
    end

    # Module to hold generated methods. Single for all status fields in model.
    def statusable_methods
      # Include generated methods with a module, not right in class.
      @statusable_methods ||= Module.new.tap do |m|
        m.const_set :ClassMethods, Module.new
        include m
        extend m::ClassMethods
      end
    end
  end
end
