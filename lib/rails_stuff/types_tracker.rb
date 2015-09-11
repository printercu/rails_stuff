require 'active_support/core_ext/class/attribute'

module RailsStuff
  # Adds `types_list` method which tracks all descendants.
  # Also allows to remove any of descendants from this list.
  # Useful for STI models to track all available types.
  #
  # Railtie adds `to_prepare` callback, which will automatically load types.
  module TypesTracker
    class << self
      def extended(base)
        base.class_attribute :types_list, instance_accessor: false
        base.types_list = types_list_class.new
      end

      # Class for `types_list`. Default to `Array`. You can override it
      # for all models, or assign new value to specific model
      # via `lypes_list=` right after extending.
      attr_accessor :types_list_class
    end

    self.types_list_class = Array

    # Add `self` to `types_list`.
    def register_type(*args)
      if types_list.respond_to?(:add)
        types_list.add self, *args
      else
        types_list << self
      end
    end

    # Remove `self` from `types_list`.
    def unregister_type
      types_list.delete self
    end

    # Shortcut to eager load all descendants.
    def eager_load_types!(dir = nil)
      dir ||= "#{Rails.root}/app/models/#{to_s.underscore}"
      Dir["#{dir}/*.rb"].each { |file| require_dependency file }
    end

    # Tracks all descendants automatically.
    def inherited(base)
      super
      base.register_type
    end
  end
end
