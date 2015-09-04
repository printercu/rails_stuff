require 'rails/railtie'
require 'pooled_redis'
require 'redis'
Rails.instance_eval { @redis_config = {} }
