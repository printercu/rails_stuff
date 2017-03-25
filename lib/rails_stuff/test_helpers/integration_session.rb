module RailsStuff
  module TestHelpers
    module IntegrationSession
      # Return smth usable instead of status code.
      def process(*)
        super
        response
      end

      # Set host explicitly, because it can change after request.
      def default_url_options
        super.merge(host: host)
      end

      ActionDispatch::Integration::Session.prepend(self) if defined?(ActionDispatch)
    end
  end
end
