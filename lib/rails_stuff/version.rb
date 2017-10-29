module RailsStuff
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 6
    TINY  = 0
    PRE   = 'rc3'.freeze

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

    class << self
      def to_s
        STRING
      end

      def inspect
        STRING.inspect
      end
    end
  end
end
