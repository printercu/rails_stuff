require 'active_support/concern'
require 'rails_stuff/test_helpers/concurrency'

module RailsStuff
  module RSpec
    module Concurrency
      extend ActiveSupport::Concern
      include RailsStuff::TestHelpers::Concurrency

      module ClassMethods
        # Defines subject which runs parent's value in multiple threads concurrently.
        # Define `thread_args` or `threads_count` with `let` to configure it.
        #
        # Sets metadata `concurrent: true` so database cleaner uses right strategy.
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

      ::RSpec.configuration.include(self) if defined?(::RSpec)
    end
  end
end
