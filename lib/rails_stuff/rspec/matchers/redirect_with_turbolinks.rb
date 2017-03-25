module RailsStuff
  module RSpec
    module Matchers
      module RedirectWithTurbolinks
        include ::RSpec::Matchers

        class XhrFailure < StandardError; end

        def matches?(response)
          return unless @scope.request
          if @scope.request.xhr?
            match_unless_raises(XhrFailure) { matches_xhr?(response) }
          else
            super
          end
        end

        def failure_message
          @scope.request ? super : 'Request was not performed'
        end

        def matches_xhr?(response)
          unless be_ok.matches?(response)
            raise XhrFailure, "Expect #{response.inspect} to be OK for Turbolinks redirect"
          end
          location, _options = turbolinks_location(response)
          raise XhrFailure, "No Turbolinks redirect in\n\n#{response.body}" unless location
          active_support_assertion(location)
        end

        def turbolinks_location(response)
          body = response.body
          return unless body
          match_data = /Turbolinks\.visit\(([^,]+)(,\s*([^)]+))?\)/.match(body)
          return unless match_data
          [match_data[1], match_data[3]].map { |x| JSON.parse("[#{x}]")[0] }
        end

        def active_support_assertion(location)
          redirect_is       = @scope.send(:normalize_argument_to_redirection, location)
          redirect_expected = @scope.send(:normalize_argument_to_redirection, @expected)
          message = "Expected response to be a Turbolinks redirect to <#{redirect_expected}>" \
            " but was a redirect to <#{redirect_is}>"
          @scope.assert_operator redirect_expected, :===, redirect_is, message
        rescue ActiveSupport::TestCase::Assertion => e
          raise XhrFailure, e
        end

        ::RSpec::Rails::Matchers::RedirectTo::RedirectTo.prepend(self) if defined?(::RSpec::Rails)
      end
    end
  end
end
