module RailsStuff
  module ResourcesController
    # Default responder class.
    class Responder < ActionController::Responder
      include Responders::FlashResponder
      include Responders::HttpCacheResponder

      # Similar to `.to_html`. Redirect is performed via turbolinks.
      def to_js
        default_render
      rescue ActionView::MissingTemplate
        raise if get?
        if has_errors?
          render resource.persisted? ? :edit : :new
        else
          redirect_via_turbolinks_to controller.url_for(resource_location)
        end
      end
    end
  end
end
