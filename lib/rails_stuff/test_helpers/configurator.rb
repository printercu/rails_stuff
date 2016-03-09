module RailsStuff
  module TestHelpers
    # Collection of useful RSpec configurations.
    #
    #     RailsStuff::TestHelpers::Configurator.tap do |configurator|
    #       configurator.database_cleaner(config)
    #       # ...
    #     end
    #
    module Configurator
      module_function

      # Setups database cleaner to use strategy depending on metadata.
      # By default it uses `:transaction` for all examples and `:truncation`
      # for features and examples with `concurrent: true`.
      #
      # Other types can be tuned with `config.cleaner_strategy` hash &
      # `config.cleaner_strategy.default`.
      def database_cleaner(config)
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

      # Setups redis to flush db after suite and before each example with
      # `flush_redis: :true`. `Rails.redis` client is used by default.
      # Can be tuned with `config.redis`.
      def redis(config)
        config.add_setting :redis
        config.redis = Rails.redis if defined?(Rails.redis)
        config.before { |ex| config.redis.flushdb if ex.metadata[:flush_redis] }
        config.after(:suite) { config.redis.flushdb }
      end
    end
  end
end
