require 'active_support/concern'
require 'active_support/core_ext/array/wrap'

module RailsStuff
  module TestHelpers
    module Concurrency
      extend ActiveSupport::Concern

      class << self
        # Default threads count
        attr_accessor :threads_count
      end
      @threads_count = 3

      module ClassMethods
        # Defines subject which runs parent's value in multiple threads concurrently.
        # Define `thread_args` or `threads_count` with `let` to configure it.
        def concurrent_subject!
          metadata[:concurrent] = true
          subject do
            super_proc = super()
            args = defined?(thread_args) && thread_args
            args ||= defined?(threads_count) && threads_count
            -> { concurrently(args, &super_proc) }
          end
        end

        # Runs given block in current context and nested context with concurrent subject.
        #
        #     subject { -> { increment_value_once } }
        #     # This will create 2 examples. One for current contex, and one
        #     # for current context where subject will run multiple times concurrently.
        #     check_concurrent do
        #       it { should change { value }.by(1) }
        #     end
        def check_concurrent(&block)
          instance_eval(&block)
          context 'running multiple times concurrently' do
            concurrent_subject!
            instance_eval(&block)
          end
        end
      end

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
