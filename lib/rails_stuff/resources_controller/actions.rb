module RailsStuff
  module ResourcesController
    # Basic actions for resources controller.
    module Actions
      def new
        build_resource
      end

      def create(options = {}, &block)
        if create_resource
          options[:location] ||= after_save_url
        end
        respond_with(resource, options, &block)
      end

      def update(options = {}, &block)
        if update_resource
          options[:location] ||= after_save_url
        end
        respond_with(resource, options, &block)
      end

      def destroy(options = {}, &block)
        resource.destroy
        options[:location] ||= after_destroy_url
        flash_errors!
        respond_with(resource, options, &block)
      end
    end
  end
end
