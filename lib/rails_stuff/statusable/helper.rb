module RailsStuff
  module Statusable
    # Class to hold helper methods for statusable field.
    #
    #   Order.has_status_field :status, %i(pending complete)
    #   Order.statuses.list # => %(pending complete)
    #   # ...
    class Helper
      attr_reader :model, :field, :list

      def initialize(model, field, statuses)
        @model = model
        @field = field.freeze
        @list = statuses.freeze
      end

      def translate(status)
        model.t(".#{field}_name.#{status}") if status
      end

      alias_method :t, :translate

      # Returns array compatible with select_options helper.
      def select_options(only: nil, except: nil)
        only ||= list
        only -= except if except
        only.map { |x| [translate(x), x] }
      end

      # Generate class method in model to access helper.
      def attach(method_name = field.to_s.pluralize)
        helper = self
        define_class_method(method_name) { helper }
      end

      # Rails 4 doesn't use `instance_exec` for scopes, so we do it manually.
      # For Rails 5 it's just use `.scope`.
      def define_scope(name, body)
        if RailsStuff.rails4?
          model.singleton_class.send(:define_method, name) do |*args|
            all.scoping { instance_exec(*args, &body) } || all
          end
        else
          model.scope(name, body)
        end
      end

      def define_method(method, &block)
        methods_module.send(:define_method, method, &block)
      end

      def define_class_method(method, &block)
        methods_module::ClassMethods.send(:define_method, method, &block)
      end

      protected

      # Module to hold generated methods.
      def methods_module
        model.statusable_methods
      end
    end
  end
end
