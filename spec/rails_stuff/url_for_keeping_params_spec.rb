require 'integration_helper'
require 'rails_stuff/url_for_keeping_params'

RSpec.describe ActionDispatch::Routing::UrlFor, type: :controller do
  controller Site::UsersController do
    def index
      head :ok
    end
  end

  describe '#url_for_keeping_params' do
    it 'keeps query params of url' do
      allow(request).to receive(:request_parameters) { {user: 'name'} }
      get :index, sort: :date, page: 1
      expect(controller.url_for_keeping_params page: 2, limit: 5).
        to eq controller.url_for(sort: :date, page: 2, limit: 5)
      expect(controller.params).to include user: 'name'
    end

    it 'removes param when overwritten wit nil' do
      get :index, sort: :date, page: 1
      expect(controller.url_for_keeping_params page: nil, limit: 5).
        to eq controller.url_for(sort: :date, limit: 5)
    end

    context 'when used in a view' do
      controller Site::UsersController do
        def index
          render inline: '<%= raw url_for_keeping_params page: 2, limit: 5 %>'
        end
      end

      it 'works the same way' do
        get :index, sort: :date, page: 1
        expect(response.body).
          to eq controller.url_for(sort: :date, page: 2, limit: 5, only_path: true)
      end
    end
  end
end
