module RailsStuff
  module Responders
    module Turbolinks
      # Bypasses `:turbolinks` from options.
      def redirect_to(url, opts = {})
        if !opts.key?(:turbolinks) && options.key?(:turbolinks)
          opts[:turbolinks] = options[:turbolinks]
        end
        super
      end
    end
  end
end
