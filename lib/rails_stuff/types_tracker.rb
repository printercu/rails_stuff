require 'active_support/core_ext/class/attribute'
require 'active_support/deprecation'

module RailsStuff
  # Adds `types_list` method which tracks all descendants.
  # Also allows to remove any of descendants from this list.
  # Useful for STI models to track all available types.
  #
  # Use with RequireNested to preload all nested classes.
  module TypesTracker
    class << self
      def extended(base)
        base.class_attribute :types_list, instance_accessor: false
        base.types_list = types_list_class.new
        base.instance_variable_set(:@_types_tracker_base, base)
      end

      # Class for `types_list`. Default to `Array`. You can override it
      # for all models, or assign new value to specific model
      # via `lypes_list=` right after extending.
      attr_accessor :types_list_class
    end

    self.types_list_class = Array

    # Add `self` to `types_list`. Defines scope for ActiveRecord models.
    def register_type(*args)
      if types_list.respond_to?(:add)
        types_list.add self, *args
      else
        types_list << self
      end
      if types_tracker_base.respond_to?(:scope) &&
          !types_tracker_base.respond_to?(model_name.element)
        type_name = name
        types_tracker_base.scope model_name.element, -> { where(type: type_name) }
      end
    end

    # Remove `self` from `types_list`. It doesnt remove generated scope
    # from ActiveRecord models, 'cause it potentialy can remove other methods.
    def unregister_type
      types_list.delete self
    end

    # Tracks all descendants automatically.
    def inherited(base)
      super
      base.register_type
    end

    # Class that was initilly extended with TypesTracker.
    def types_tracker_base
      @_types_tracker_base || superclass.types_tracker_base
    end
  end
end
