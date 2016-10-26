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
    def has_status_field(field = :status, statuses = nil, helper: nil, **options)
      unless statuses
        const_name = "#{field.to_s.pluralize.upcase}_MAPPING"
        const_name = field.to_s.pluralize.upcase unless const_defined?(const_name)
        statuses = const_get(const_name)
      end
      helper ||= statuses.is_a?(Hash) ? MappedHelper : Helper
      helper = helper.new(self, field, statuses)
      helper.attach
      helper.generate_methods(options)
    end
  end
end
