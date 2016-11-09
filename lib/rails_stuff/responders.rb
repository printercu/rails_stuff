require 'rails_stuff/responders/turbolinks'

module RailsStuff
  # Here are some useful responders extensions.
  #
  # Previous versions had responder with SJR helpers, which has been removed.
  # To achieve same result define responder with:
  #
  #   class CustomResponder < ActionController::Responder
  #     include Responders::HttpCacheResponder
  #     include RailsStuff::Responders::Turbolinks
  #
  #     # SJR: render action on failures, redirect on success
  #     alias_method :to_js, :to_html
  #   end
  #
  module Responders
  end
end
