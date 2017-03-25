require 'active_support/core_ext/array/wrap'

module RailsStuff
  module TestHelpers
    module Concurrency
      class << self
        # Default threads count
        attr_accessor :threads_count
      end
      @threads_count = 3

      extend self

      # Runs block concurrently in separate threads.
      # Pass array of args arrays to run each thread with its own arguments.
      # Or pass Integer to run specified threads count with same arguments.
      # Default is to run Concurrency.threads_count threads.
      #
      #    concurrently { do_something }
      #    concurrently(5) { do_something }
      #    concurrently([[1, opt: true], [2, opt: false]]) do |arg, **options|
      #      do_something(arg, options)
      #    end
      #    # It'll automatically wrap single args into Array:
      #    concurrently(1, 2, {opt: true}, {opt: false}, [1, opt: false]) { ... }
      #
      def concurrently(thread_args = nil)
        thread_args ||= Concurrency.threads_count
        threads =
          case thread_args
          when Integer
            Array.new(thread_args) { Thread.new { yield } }
          else
            thread_args.map { |args| Thread.new { yield(*Array.wrap(args)) } }
          end
        threads.each(&:join)
      end
    end
  end
end
