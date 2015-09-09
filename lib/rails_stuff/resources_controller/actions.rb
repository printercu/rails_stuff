module RailsStuff
  module ResourcesController
    # Basic actions for resources controller.
    module Actions
      def new
        build_resource
      end

      def create(options = {})
        if create_resource
          options[:location] = after_save_url
        end
        respond_with(resource, options)
      end

      def update(options = {})
        if update_resource
          options[:location] = after_save_url
        end
        respond_with(resource, options)
      end

      def destroy(options = {})
        resource.destroy
        options[:location] = after_destroy_url
        flash_errors!
        respond_with(resource, options)
      end
    end
  end
end
