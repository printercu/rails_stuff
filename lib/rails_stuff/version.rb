module RailsStuff
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 5
    TINY  = 1
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end
end
