require 'active_support/concern'

module RailsStuff
  module RSpec
    module Groups
      module Request
        extend ActiveSupport::Concern

        included do
          # Define default params for ResourcesController.
          #
          #   subject { -> { post(resource_path, params: params) } }
          #   let(:resource) { create(:user) }
          #   let(:resource_params) { {name: 'new name'} }
          if described_class.respond_to?(:resource_param_name)
            let(:params) { {described_class.resource_param_name => resource_params} }
          end
        end

        module ClassMethods
          # Adds `referer`, `referer_path` and `headers` with `let`.
          # Requires `root_url`
          def set_referer
            let(:referer) { root_url.sub(%r{/$}, referer_path) }
            let(:referer_path) { '/test_referer' }
            let(:headers) do
              headers = {Referer: referer}
              defined?(super) ? super().merge(headers) : headers
            end
          end

          # Perform simple request to initialize session.
          # Useful for `change` matchers.
          def init_session
            before do
              path = defined?(init_session_path) ? init_session_path : '/'
              get(path)
            end
          end

          def with_csrf_protection!
            around do |ex|
              begin
                old = ActionController::Base.allow_forgery_protection
                ActionController::Base.allow_forgery_protection = true
                ex.run
              ensure
                ActionController::Base.allow_forgery_protection = old
              end
            end
            let(:csrf_response) do
              path = defined?(csrf_response_path) ? csrf_response_path : '/'
              get(path) && response.body
            end
            let(:csrf_param) { csrf_response.match(/meta name="csrf-param" content="([^"]*)"/)[1] }
            let(:csrf_token) { csrf_response.match(/<meta name="csrf-token" content="([^"]*)"/)[1] }
          end
        end

        # Generate url to current controller.
        def controller_path(**options)
          url_for(controller: described_class.controller_path, only_path: true, **options)
        end

        # Generate url to current controller with resource and default action to `:show`.
        # It uses `resource` method by default:
        #
        #   expect(resource_path).to eq resource_path(resource)
        #   resource_path(other_user, action: :edit)
        def resource_path(resource = self.resource, **options)
          controller_path(action: :show, id: resource, **options)
        end

        ::RSpec.configuration.include self, type: :request
      end
    end
  end
end
