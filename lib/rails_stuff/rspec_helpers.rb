require 'active_support/core_ext/array/wrap'
require 'active_support/dependencies/autoload'

module RailsStuff
  # Collection of RSpec configurations and helpers for better experience.
  module RSpecHelpers
    autoload :Signinable, 'rails_stuff/rspec_helpers/signinable'

    extend self

    # Single endpoint for multiple seups. Use `:only` and `:except` options
    # to filter actions.
    def setup(only: nil, except: nil)
      items = instance_methods.map(&:to_s) - %w(setup)
      items -= Array.wrap(except).map(&:to_s) if except
      if only
        only = Array.wrap(only).map(&:to_s)
        items &= only
        items += only
      end
      items.uniq.each { |item| public_send(item) }
    end

    %w(
      concurrency
      groups/request
      groups/feature
      matchers/be_valid_js
      matchers/redirect_with_turbolinks
    ).each do |file|
      define_method(file) { require "rails_stuff/rspec_helpers/#{file}" }
    end

    # Setup all TestHelpers.
    def test_helpers
      TestHelpers.setup
    end

    # Setups database cleaner to use strategy depending on metadata.
    # By default it uses `:transaction` for all examples and `:truncation`
    # for features and examples with `concurrent: true`.
    #
    # Other types can be tuned with `config.cleaner_strategy` hash &
    # `config.cleaner_strategy.default`.
    def database_cleaner # rubocop:disable AbcSize
      return unless defined?(DatabaseCleaner)
      ::RSpec.configure do |config|
        if config.respond_to?(:use_transactional_fixtures=)
          config.use_transactional_fixtures = false
        end
        config.add_setting :database_cleaner_strategy
        config.database_cleaner_strategy = {feature: :truncation}
        config.database_cleaner_strategy.default = :transaction
        config.add_setting :database_cleaner_options
        config.database_cleaner_options = {truncation: {except: %w(spatial_ref_sys)}}
        config.add_setting :database_cleaner_args
        config.database_cleaner_args = ->(ex) do
          strategy = ex.metadata[:concurrent] && :truncation
          strategy ||= config.database_cleaner_strategy[ex.metadata[:type]]
          options = config.database_cleaner_options[strategy] || {}
          [strategy, options]
        end
        config.around do |ex|
          DatabaseCleaner.strategy = config.database_cleaner_args.call(ex)
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
        config.add_setting :flush_redis_proc
        config.flush_redis_proc = ->(*) { Array.wrap(config.redis).each(&:flushdb) }
        config.before(flush_redis: true) { instance_exec(&config.flush_redis_proc) }
        config.after(:suite) { instance_exec(&config.flush_redis_proc) }
      end
    end

    # Runs debugger after each failed example with `:debug` tag.
    # Uses `pry` by default, this can be configured `config.debugger=`.
    def debug
      ::RSpec.configure do |config|
        config.add_setting :debugger_proc
        config.debugger_proc = ->(ex) do
          exception = ex.exception
          defined?(Pry) ? binding.pry : debugger # rubocop:disable Debugger
        end
        config.after(debug: true) do |ex|
          instance_exec(ex, &config.debugger_proc) if ex.exception
        end
      end
    end

    # Clear logs `tail -f`-safely.
    def clear_logs
      ::RSpec.configure do |config|
        config.add_setting :clear_log_file
        config.clear_log_file = Rails.root.join('log', 'test.log') if defined?(Rails.root)
        config.add_setting :clear_log_file_proc
        config.clear_log_file_proc = ->(file) do
          next unless file && File.exist?(file)
          FileUtils.cp(file, "#{file}.last")
          File.open(file, 'w').close
        end
        config.after(:suite) do
          instance_exec(config.clear_log_file, &config.clear_log_file_proc) unless ENV['KEEP_LOG']
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
