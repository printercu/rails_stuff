require 'active_support/dependencies'

module RailsStuff
  module RequireNested
    class << self
      # Make #require_nested available in module.
      def setup
        Module.include(self)
      end
    end

    module_function

    # Requires nested modules with `require_dependency`.
    # Pass custom directory to require its content.
    # By default uses caller's filename with stripped `.rb` extension from.
    def require_nested(dir = 0)
      dir = caller_locations(dir + 1, 1)[0].path.sub(/\.rb$/, '') if dir.is_a?(Integer)
      Dir["#{dir}/*.rb"].each { |file| require_dependency file }
    end
  end
end
