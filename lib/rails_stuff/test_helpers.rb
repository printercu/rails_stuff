require 'active_support/core_ext/array/wrap'

module RailsStuff
  # Collection of RSpec configurations and helpers for better experience.
  module TestHelpers
    extend self

    def setup(only: nil, except: nil)
      items = instance_methods.map(&:to_s) - %w(setup)
      items -= Array.wrap(except).map(&:to_s) if except
      if only
        only = Array.wrap(only).map(&:to_s)
        items &= only
        items += only
      end
      items.each { |item| public_send(item) }
    end

    %w(
      integration_session
      response
    ).each do |file|
      define_method(file.tr('/', '_')) { require "rails_stuff/test_helpers/#{file}" }
    end

    # Make BigDecimal`s more readable.
    def big_decimal
      require 'bigdecimal'
      BigDecimal.class_eval do
        alias_method :inspect_orig, :inspect
        alias_method :inspect, :to_s
      end
    end

    # Raise errors from failed threads.
    def thread
      Thread.abort_on_exception = true
    end

    # Raise all translation errors, to not miss any of translations.
    # Make sure to set `config.action_view.raise_on_missing_translations = true` in
    # `config/environments/test.rb` yourself.
    def i18n
      return unless defined?(I18n)
      I18n.config.exception_handler = ->(exception, _locale, _key, _options) do
        raise exception.respond_to?(:to_exception) ? exception.to_exception : exception
      end
    end
  end
end
