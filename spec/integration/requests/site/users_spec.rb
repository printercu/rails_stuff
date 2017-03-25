require 'integration_helper'

RSpec.describe Site::UsersController, :db_cleaner, type: :request do
  let(:resource) { User.create_default! }
  let(:resource_id) { resource.id }
  let(:other_resource) { User.create_default!(email: 'other@example.com') }
  let(:controller_resource) { controller.send :resource }

  describe '#index' do
    subject { get controller_path, params: params }
    let(:params) { {} }
    let(:collection) do
      should render_template :index
      controller.send(:collection)
    end
    let!(:resources) { [resource, other_resource] }

    it 'renders index' do
      expect(collection.all.to_a).to eq resources
    end

    context 'when pagination params are given' do
      let(:params) { {page: 10, per: 2} }
      it 'paginates collection' do
        expect(collection.offset_value).to eq 18
        expect(collection.limit_value).to eq 2
      end

      context 'and param for has_scope is given' do
        let(:params) { super().merge(by_email: resource.email, page: 1) }
        it 'paginates & filters collection' do
          expect(collection.all.to_a).to eq [resource]
          expect(collection.offset_value).to eq 0
          expect(collection.limit_value).to eq 2
        end
      end
    end

    context 'when param for has_scope is given' do
      let(:params) { {by_email: resource.email} }
      it 'filters collection' do
        expect(collection.all.to_a).to eq [resource]
      end
    end
  end

  describe '#show' do
    subject { get resource_path }

    it 'finds resource and renders template' do
      should render_template :show
      expect(controller_resource).to eq resource
    end

    context 'when resource is not found' do
      before { resource.destroy }
      it { should be_not_found }
    end
  end

  describe '#new' do
    subject { get controller_path(action: :new), params: params }
    let(:resource_params) { {name: 'New name', admin: true} }

    it 'initializes new resource' do
      should render_template :new
      expect(controller_resource).to be_instance_of User
      expect(controller_resource.attributes).to include(
        'name' => 'New name',
        'admin' => false,
      )
    end
  end

  describe '#create' do
    subject { post controller_path, params: params }
    let(:resource_params) { {name: 'New name', email: 'test', admin: true} }

    it 'redirects to created user path' do
      expect { should be_redirect }.to change(User, :count).by(1)
      resource = User.last
      expect(resource.name).to eq 'New name'
      should redirect_to site_user_path(resource)
    end

    context 'when create fails' do
      let(:resource_params) { super().except(:email) }

      it 'renders :new' do
        expect { should render_template :new }.to_not change(User, :count)
        expect(controller_resource.attributes).to include(
          'name' => 'New name',
          'admin' => false,
        )
      end
    end
  end

  describe '#edit' do
    subject { get resource_path(action: :edit) }

    it 'finds resource and renders template' do
      should render_template :edit
      expect(controller_resource).to eq resource
    end

    context 'when resource is not found' do
      before { resource.destroy }
      it { should be_not_found }
    end
  end

  describe '#update' do
    subject { patch resource_path, params: params }
    let(:resource_params) { {name: 'New name', admin: true} }

    context 'when update succeeds' do
      it 'redirects to user path' do
        expect { should be_redirect }.
          to change { resource.reload.name }.to('New name')
        expect(resource.admin).to eq false
        should redirect_to site_user_path(resource)
      end
    end

    context 'when update fails' do
      let(:resource_params) { {name: '', admin: true} }

      it 'renders :edit' do
        expect { should render_template :edit }.
          to_not change { resource.reload.name }
        expect(controller_resource.attributes).to include(
          'name' => '',
          'admin' => false,
        )
      end
    end

    context 'when resource is not found' do
      before { resource.destroy }
      it { should be_not_found }
    end
  end

  describe '#destroy' do
    subject { delete resource_path }

    context 'when destroy succeeds' do
      it 'redirects to index' do
        expect { should redirect_to site_users_path }.
          to change { User.find_by_id resource.id }.to(nil)
      end
    end

    context 'when destroy fails' do
      before do
        expect_any_instance_of(User).to receive(:destroy) do |instance|
          instance.errors.add :base, :forbidden
        end
      end

      it 'redirects to index and flashes error' do
        expect { should redirect_to site_users_path }.
          to_not change { User.find_by_id resource.id }
        expect(controller_resource.errors[:base]).to be_present
        expect(flash[:error]).to be_present
      end
    end

    context 'when resource is not found' do
      before { resource.destroy }
      it { should be_not_found }
    end
  end

  describe '.action_methods' do
    subject { described_class.action_methods }
    it { should_not include 'source_for_collection' }
  end
end
