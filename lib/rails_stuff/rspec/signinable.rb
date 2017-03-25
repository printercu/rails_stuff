module RailsStuff
  module RSpec
    module Signinable
      # Context-level helper to add before filter to sign in user.
      # Adds `current_user` with let if not defined yet or with gven block.
      #
      # Instance-level `sign_in(user_or_nil)` method must be defined, so
      # this module can be used in any of feature, request or controller groups.
      #
      #     sign_in { owner }
      #     sign_in # will call current_user or define it with nil
      def sign_in(&block)
        if block || !instance_methods.include?(:current_user)
          block ||= ->(*) {}
          let(:current_user, &block)
        end
        before { sign_in(instance_eval { current_user }) }
      end
    end
  end
end
