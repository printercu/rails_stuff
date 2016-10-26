module RailsStuff
  module ResourcesController
    module BasicHelpers
      extend ActiveSupport::Concern

      included do
        helper_method :resource, :collection
        self.after_save_action = :show
      end

      module ClassMethods
        attr_writer :resource_class,
                    :resource_param_name,
                    :permitted_attrs

        # Defines action to redirect after resource was saved. Default to `:show`.
        attr_accessor :after_save_action

        # Resource class for controller. Default to class, based on
        # demodulized controller name.
        def resource_class
          @resource_class ||=
            Object.const_get(name.to_s.demodulize.sub(/Controller$/, '').singularize)
        end

        # Key to lookup for resource attributes in `params`.
        # Default to class'es `param_key`.
        def resource_param_name
          @resource_param_name ||= resource_class.model_name.param_key
        end

        # Class-level permitted attributes.
        #
        # `attr_reader`, default to `[]`.
        def permitted_attrs
          @permitted_attrs ||= []
        end

        # Concats `@permitted_attrs` variable with given attrs.
        def permit_attrs(*attrs)
          permitted_attrs.concat attrs
        end

        # Prevent CanCan's implementation.
        def authorize_resource
          raise 'use `before_action :authorize_resource!` instead'
        end
      end

      protected

      # Accesss resources collection.
      def collection
        @_collection ||= source_for_collection
      end

      # End-point relation to be used as source for `collection`.
      def source_for_collection
        source_relation
      end

      # Relation which is used to find and build resources.
      def source_relation
        self.class.resource_class
      end

      # Resource found by `params[:id]`
      def resource
        @_resource ||= source_relation.find params[:id]
      end

      # Instantiate resource with attrs from `resource_params`.
      def build_resource(attrs = resource_params)
        @_resource = source_relation.new(attrs)
      end

      # Builds and saves resource.
      def create_resource
        build_resource
        resource.save
      end

      # Updates resource with `resource_params`.
      def update_resource(attrs = resource_params)
        resource.update(attrs)
      end

      # Flashes errors in a safe way. Joins `full_messages` and truncates
      # result to avoid cookies overflow.
      def flash_errors!(errors = resource.errors, max_length = 100)
        flash[:error] = errors.full_messages.join("\n").truncate(max_length) if errors.any?
      end

      # URL to be used in `Location` header & to redirect to after
      # resource was created/updated. Default uses `self.class.after_save_action`.
      def after_save_url
        action = self.class.after_save_action
        if action == :index
          index_url
        else
          url_for action: action, id: resource
        end
      end

      # URL to be used in `Location` header & to redirect after
      # resource was destroyed. Default to #index_url.
      def after_destroy_url
        index_url
      end

      # Extracted from #after_save_url and #after_destroy_url because they use
      # same value. It's easier to override this urls in one place.
      def index_url
        url_for action: :index
      end

      # Override it to return permited params. By default it returns params
      # using `self.class.resource_param_name` and `permitted_attrs` methods.
      def resource_params
        @_resource_params ||= begin
          key = self.class.resource_param_name
          params.permit(key => permitted_attrs)[key] || params.class.new
        end
      end

      # Default permitted attributes are taken from class method. Override it
      # to implement request-based permitted attrs.
      def permitted_attrs
        self.class.permitted_attrs
      end

      # Default authorization implementation.
      # Uses `#authorize!` method which is not implemented here
      # (use CanCan or other implementation).
      def authorize_resource!
        action = action_name.to_sym
        target =
          case action
          when :index, :create, :new then self.class.resource_class.new
          else resource
          end
        authorize!(action, target)
      end
    end
  end
end
