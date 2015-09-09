require 'net/http'

class << Net::HTTP
  # Redefines `.new` to set debug device for all new instances.
  def debug!(out = $stderr)
    return if respond_to?(:__new__)
    class << self
      alias_method :__new__, :new
    end

    define_singleton_method :new do |*args, &blk|
      instance = __new__(*args, &blk)
      instance.set_debug_output(out)
      instance
    end
  end

  # Restores original `.new`.
  def disable_debug!
    return unless respond_to?(:__new__)
    class << self
      alias_method :new, :__new__
      remove_method :__new__
    end
  end
end
