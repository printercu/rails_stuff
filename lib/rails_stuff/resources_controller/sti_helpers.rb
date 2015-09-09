require 'active_record/errors'

module RailsStuff
  module ResourcesController
    # Helper methods for controllers which works with STI models.
    module StiHelpers
      extend ActiveSupport::Concern

      module ClassMethods
        # Returns hash which is used to get subclass for requested type.
        #
        # By default it uses `.types_list` or `.descendants` to get list of
        # classes and indexes them by class names.
        def resource_class_by_type
          @resource_class_by_type ||= begin
            if resource_class.respond_to?(:types_list)
              resource_class.types_list
            else
              resource_class.descendants
            end.index_by(&:name)
          end
        end

        # Class-level accessor to permitted attributes for specisic class.
        def permitted_attrs_for
          @permitted_attrs_for ||= Hash.new { |h, k| h[k] = [] }
        end

        # Permits attrs only for specific class.
        def permit_attrs_for(klass, *attrs)
          permitted_attrs_for[klass].concat attrs
        end
      end

      protected

      # Returns model class depending on `type` attr in params.
      # If resource is requested by id, it returns its class.
      def class_from_request
        @class_from_request ||=
          if params.key?(:id)
            resource.class
          else
            name = params.require(self.class.resource_param_name).
              permit(:type)[:type]
            self.class.resource_class_by_type[name] ||
              raise(ActiveRecord::RecordNotFound)
          end
      end

      # Instantiates object using class_from_request.
      def build_resource
        @_resource = super.becomes!(class_from_request)
      end

      # Merges default attrs with attrs for specific class.
      def permitted_attrs
        super + self.class.permitted_attrs_for[class_from_request]
      end
    end
  end
end
