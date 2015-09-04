require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/remove_method'
require 'active_support/core_ext/object/blank'

module RailsStuff
  # Provides methods to store data in redis. Can be easily integrated into
  # ActiveRecor or other class.
  #
  # Redis is accessed via with_redis method which uses redis_pool
  # (default to `Rails.redis_pool`, see `pooled_redis` gem) to checkout connection.
  # Basic methods are get, delete and set.
  #
  # Redis keys are generated from requested key and redis_prefix
  # (default to underscored class name). You can pass array as a key and all the
  # parts will be concatenated with ':'. set automalically generates
  # sequential keys, if given key is nil (last element of array is nil).
  module RedisStorage
    # Serializers
    delegate :dump, :load, to: Marshal

    # Redis connections pool. Default to `Rails.redis_pool`.
    # Override this method to change it.
    def redis_pool
      Rails.redis_pool
    end

    # Options to use in SET command. Use to set EX, or smth.
    def redis_set_options
      {}
    end

    # :method: redis_pool=
    # :call-seq: redis_pool=
    #
    # Set redis_pool.

    # :method: redis_set_options=
    # :call-seq: redis_set_options=
    #
    # Set redis_set_options.

    # Setters that overrides methods, so new values are inherited without recursive `super`.
    [:redis_pool, :redis_set_options].each do |name|
      define_method "#{name}=" do |val|
        singleton_class.class_eval do
          remove_possible_method(name)
          define_method(name) { val }
        end
      end
    end

    # Checkout connection & run block with it.
    def with_redis(&block)
      redis_pool.with(&block)
    end

    # Prefix that used in every key for a model. Default to pluralized model name.
    def redis_prefix
      @redis_prefix ||= name.underscore
    end

    # Override default redis_prefix.
    attr_writer :redis_prefix

    # Generates key for given id(s) prefixed with #redis_prefix.
    # Multiple ids are joined with `:`.
    def redis_key_for(id)
      "#{redis_prefix}:#{Array(id).join(':')}"
    end

    # Generates key to store current id. Examples:
    #
    #     users_id_seq
    #     user_id_seq:eu
    def redis_id_seq_key(id = [])
      postfix = Array(id).join(':')
      "#{redis_prefix}_id_seq#{":#{postfix}" if postfix.present?}"
    end

    # Generate next ID. It stores counter separately and uses
    # it to retrieve next id.
    def next_id(*args)
      with_redis { |redis| redis.incr(redis_id_seq_key(*args)) }
    end

    # Reset ID counter.
    def reset_id_seq(*args)
      with_redis { |redis| redis.del(redis_id_seq_key(*args)) }
    end

    # Saves value to redis. If id is nil, it's generated with #next_id.
    # Returns last part of id / generated id.
    def set(id, value, options = {})
      id = Array(id)
      id.push(nil) if id.empty?
      id[id.size - 1] ||= next_id(id[0..-2])
      with_redis do |redis|
        redis.set(redis_key_for(id), dump(value), redis_set_options.merge(options))
      end
      id.last
    end

    # Reads value from redis.
    def get(id)
      return unless id
      with_redis { |redis| redis.get(redis_key_for(id)).try { |data| load(data) } }
    end

    # Remove record from redis.
    def delete(id)
      return true unless id
      with_redis { |redis| redis.del(redis_key_for(id)) }
      true
    end
  end
end
