module RailsStuff
  module ResourcesController
    module KaminariHelpers
      protected

      # Make source_for_collection use Kaminari-style scopes to paginate relation.
      def source_for_collection
        super.page(params[:page]).per(params[:per])
      end

      module ConfigMethods
        def use_kaminari!(val = true)
          @use_kaminari = val
        end

        def use_kaminari?
          @use_kaminari
        end
      end
    end
  end
end
