require 'integration_helper'

RSpec.describe Site::ProjectsController, :db_cleaner, type: :request do
  let(:user) { User.create_default! }
  let(:user_id) { user.id }
  let(:resource) { Project.create_default!(user: user) }
  let(:resource_id) { resource.id }
  let(:other_user) { User.create_default! }
  let(:other_resource) { Project.create_default!(user: other_user) }
  let(:controller_resource) { controller.send :resource }

  describe '#index' do
    subject { get controller_path(user_id: user.id), params: params }
    let(:params) { {} }
    before { resource && other_resource }

    it 'renders index, and limits collection to parent`s resources' do
      should render_template :index
      expect(controller.send(:collection).all.to_a).to eq [resource]
    end

    context 'when pagination params are given' do
      let(:params) { {user_id: user.id, page: 10, per: 2} }
      it 'paginates collection' do
        should render_template :index
        collection = controller.send(:collection)
        expect(collection.offset_value).to eq 18
        expect(collection.limit_value).to eq 2
      end
    end

    context 'when parent is not found' do
      before { user.destroy }
      it { should be_not_found }
    end
  end

  describe '#create' do
    subject { -> { post controller_path(user_id: user_id), params: params } }
    let(:resource_params) do
      {
        name: 'New project',
        user_id: other_user.id,
        department: 'D',
        company: 'C',
        type: 'Project::Internal',
      }
    end

    context 'when create succeeds' do
      it 'redirects to created user path' do
        should change { user.projects.count }.by(1)
        resource = user.projects.last
        expect(resource.attributes).to include(
          'name' => 'New project',
          'department' => 'D',
          'company' => nil,
        )
        should redirect_to site_project_path(resource)
      end

      it 'respects per-type allowed attributes' do
        resource_params[:type] = 'Project::External'
        should change { user.projects.count }.by(1)
        resource = user.projects.last
        should redirect_to site_project_path(resource)
        expect(resource.attributes).to include(
          'name' => 'New project',
          'department' => nil,
          'company' => 'C',
        )
      end
    end

    context 'when create fails' do
      let(:resource_params) { super().except(:name) }

      it 'renders index' do
        should_not change(Project, :count)
        expect(response).to render_template :index
        expect(controller_resource.attributes).to include(
          'user_id' => user.id,
          'name' => nil,
          'department' => 'D',
          'company' => nil,
        )
      end
    end

    context 'when invalid type is requested' do
      let(:resource_params) { super().merge(type: 'Project::Hidden') }
      its(:call) { should be_unprocessable_entity }
    end

    context 'when parent is not found' do
      let(:user_id) { -1 }
      its(:call) { should be_not_found }
    end
  end

  describe '#update' do
    subject { patch(resource_path, params: params) }
    let(:resource_params) do
      {
        name: 'New project',
        user_id: other_user.id,
        department: 'D',
        company: 'C',
        type: 'Project::Hidden',
      }
    end

    context 'when update succeeds' do
      it 'redirects to index' do
        expect { should be_redirect }.
          to change { resource.reload.attributes.slice('name', 'department', 'company', 'type') }.
          to(
            'name' => 'New project',
            'department' => nil,
            'company' => 'C',
            'type' => 'Project::External',
          )
        should redirect_to site_project_path(user)
      end

      context 'when resource is of other type' do
        let(:resource) { super().becomes!(Project::Internal).tap(&:save!) }

        it 'respects per-type allowed attributes' do
          expect { should redirect_to site_project_path(user) }.
            to change { resource.reload.attributes.slice('name', 'department', 'company', 'type') }.
            to(
              'name' => 'New project',
              'department' => 'D',
              'company' => nil,
              'type' => 'Project::Internal',
            )
        end
      end
    end

    context 'when update fails' do
      let(:resource_params) { super().merge(name: '') }

      it 'renders edit' do
        expect { should render_template :edit }.
          to_not change { resource.reload.attributes }
        expect(controller_resource.attributes).to include(
          'user_id' => user.id,
          'name' => '',
          'department' => nil,
          'company' => 'C',
          'type' => 'Project::External',
        )
      end
    end
  end

  describe '#destroy' do
    subject { -> { delete(resource_path) } }
    it { should change { resource.class.exists?(resource.id) }.to false }
    its(:call) { should redirect_to site_user_projects_path(user) }
  end
end
