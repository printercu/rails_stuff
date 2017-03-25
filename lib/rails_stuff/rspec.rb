require 'active_support/dependencies/autoload'

module RailsStuff
  # Collection of RSpec configurations and helpers for better experience.
  module RSpec
    # From TestHelpers module.
    BASIC_ITEMS = %w(
      integration_session
      response
    ).freeze

    # From RSpec module.
    ITEMS = %w(
      concurrency
      groups/request
      groups/feature
      matchers/be_valid_js
      matchers/redirect_with_turbolinks
    ).freeze

    autoload :Signinable, 'rails_stuff/rspec/signinable'

    extend self

    # Single endpoint for multiple seups. Use `:only` and `:except` options
    # to filter actions.
    def setup(only: nil, except: nil)
      items = BASIC_ITEMS + ITEMS + instance_methods.map(&:to_s) - %w(setup)
      items -= Array.wrap(except).map(&:to_s) if except
      items &= Array.wrap(only).map(&:to_s) if only
      items.each do |item|
        if respond_to?(item)
          public_send(item)
        elsif BASIC_ITEMS.include?(item)
          require "rails_stuff/test_helpers/#{item}"
        else
          require "rails_stuff/rspec/#{item}"
        end
      end
    end

    # Raise errors from failed threads.
    def thread
      Thread.abort_on_exception = true
    end

    # Raise all translation errors, to not miss any of translations.
    def i18n
      I18n.config.exception_handler = ->(exception, _locale, _key, _options) do
        raise exception.respond_to?(:to_exception) ? exception.to_exception : exception
      end
    end

    # All rails helpers from TestHelpers.
    def rails
      require 'action_dispatch'
      require 'rails_stuff/test_helpers/response'
      require 'rails_stuff/test_helpers/integration_session'
    end

    # Setups database cleaner to use strategy depending on metadata.
    # By default it uses `:transaction` for all examples and `:truncation`
    # for features and examples with `concurrent: true`.
    #
    # Other types can be tuned with `config.cleaner_strategy` hash &
    # `config.cleaner_strategy.default`.
    def database_cleaner
      require 'database_cleaner'
      ::RSpec.configure do |config|
        config.use_transactional_fixtures = false
        config.add_setting :cleaner_strategy
        config.cleaner_strategy = {feature: :truncation}
        config.cleaner_strategy.default = :transaction
        config.around do |ex|
          strategy = ex.metadata[:concurrent] && :truncation
          strategy ||= config.cleaner_strategy[ex.metadata[:type]]
          options = strategy == :truncation ? {except: %w(spatial_ref_sys)} : {}
          DatabaseCleaner.strategy = strategy, options
          DatabaseCleaner.cleaning { ex.run }
        end
      end
    end

    # Setups redis to flush db after suite and before each example with
    # `flush_redis: :true`. `Rails.redis` client is used by default.
    # Can be tuned with `config.redis`.
    def redis
      ::RSpec.configure do |config|
        config.add_setting :redis
        config.redis = Rails.redis if defined?(Rails.redis)
        config.before(flush_redis: true) { config.redis.flushdb }
        config.after(:suite) { config.redis.flushdb }
      end
    end

    # Runs debugger after each failed example with `:debug` tag.
    # Uses `pry` by default, this can be configured `config.debugger=`.
    def debug
      ::RSpec.configure do |config|
        config.add_setting :debugger
        config.debugger = :pry
        config.after(debug: true) do |ex|
          if ex.exception
            :pry == config.debugger ? binding.pry : debugger # rubocop:disable Debugger
            ex.exception # noop to not exit frame
          end
        end
      end
    end

    # Clear logs `tail -f`-safely.
    def clear_logs
      ::RSpec.configure do |config|
        config.add_setting :clear_log_file
        config.after(:suite) do
          next if ENV['KEEP_LOG']
          file = config.clear_log_file || Rails.root.join('log', 'test.log')
          FileUtils.cp(file, "#{file}.last")
          File.open(file, 'w').close
        end
      end
    end

    # Freeze time for specs with `:frozen_time` metadata.
    def frozen_time
      ::RSpec.configure do |config|
        config.around(frozen_time: true) { |ex| Timecop.freeze { ex.run } }
      end
    end
  end
end
