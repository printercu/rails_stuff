module RailsStuff
  module ResourcesController
    module HasScopeHelpers
      # This method overrides default `has_scope` so it include helpers from
      # InstanceMethods only when this method is called.
      def has_scope(*)
        super.tap { include InstanceMethods }
      end

      module InstanceMethods
        protected

        # Applies `has_scope` scopes to original source.
        def source_for_collection
          apply_scopes(super)
        end
      end
    end
  end
end
