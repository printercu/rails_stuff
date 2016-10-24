require 'active_model'

RSpec.describe RailsStuff::ResourcesController::BasicHelpers do
  let(:klass) { build_controller_class }
  let(:controller) { klass.new }

  def build_controller_class(class_name = nil)
    described_class = self.described_class
    build_named_class(class_name, ActionController::Base) do
      include described_class
    end
  end

  describe '.resource_class' do
    subject { ->(klass = self.klass) { klass.resource_class } }

    it 'detects class name from controller`s name' do
      stub_const('User', Class.new)
      stub_const('Product', Class.new)
      expect(subject.call build_controller_class 'UsersController').to be User
      expect(subject.call build_controller_class 'UserController').to be User
      expect(subject.call build_controller_class 'Admin::UserController').to be User
      expect(subject.call build_controller_class 'Admin::ProductsController').to be Product
    end

    context 'when class can not be automatically determined' do
      let(:klass) { build_controller_class :ProductsController }
      it { should raise_error(NameError, /uninitialized constant/) }

      context 'when class is set explicitly' do
        before { klass.resource_class = :custom_model }
        its(:call) { should eq :custom_model }
      end
    end

    context 'for anonymous class' do
      it { should raise_error(NameError, /wrong constant name/) }
    end
  end

  describe '.resource_param_name' do
    subject { ->(klass = self.klass) { klass.resource_param_name } }

    it 'takes value from class`es param_key' do
      stub_const('User', build_named_class(:Admin) { include ActiveModel::Model })
      expect(subject.call build_controller_class 'UsersController').to eq 'admin'
    end

    context 'when resource_class is set explicitly' do
      let(:model) { build_named_class(:Product) { include ActiveModel::Model } }
      let(:klass) { super().tap { |x| x.resource_class = model } }
      its(:call) { should eq 'product' }
    end

    context 'when value is set explicitly' do
      before { klass.resource_param_name = :custom_id }
      its(:call) { should eq :custom_id }
    end
  end

  describe '.permit_attrs' do
    let(:other_class) { build_controller_class }
    around { |ex| expect { ex.run }.to_not change(other_class, :permitted_attrs) }

    it 'adds args to .permitted_attrs' do
      expect { klass.permit_attrs :name, :lastname }.
        to change(klass, :permitted_attrs).from([]).to([:name, :lastname])
      expect { klass.permit_attrs project_attributes: [:id, :_destroy] }.
        to change(klass, :permitted_attrs).by([project_attributes: [:id, :_destroy]])
    end
  end

  describe '#permitted_attrs' do
    it 'returns class-level permitted_attrs by default' do
      expect { klass.permit_attrs :name }.
        to change(controller, :permitted_attrs).from([]).to([:name])
    end
  end

  describe '#resource_params' do
    subject { -> { klass.new.send(:resource_params) } }
    let(:params) do
      {
        user: {name: 'Name', lastname: 'Lastname', admin: true, id: 1},
        project: {title: 'Title', _destroy: true, id: 2},
      }
    end
    let(:params_class) { ActionController::Parameters }

    before do
      klass.resource_param_name = :user
      allow_any_instance_of(klass).to receive(:params) { params_class.new params.as_json }
    end

    it 'uses #permitted_attrs and .resource_param_name to filter params' do
      expect { klass.permit_attrs :name, :lastname, :address }.
        to change(&subject).from({}).to(name: 'Name', lastname: 'Lastname')
      expect { klass.resource_param_name = :project }.
        to change(&subject).to({})
      expect { klass.permit_attrs :title }.
        to change(&subject).to(title: 'Title')
      expect { klass.resource_param_name = :missing_key }.
        to change(&subject).to({})
    end

    context 'when resource key is not present in params' do
      before { klass.resource_param_name = :company }
      its(:call) { should be_instance_of(params_class) }
      its(:call) { should eq({}) }
    end
  end

  describe '#after_save_url' do
    it 'passes .after_save_action to url_for, and uses resource as id (except :index)' do
      allow(controller).to receive(:resource) { :resource_obj }
      expect(controller).to receive(:url_for).
        with(action: :show, id: :resource_obj) { :url }
      expect(controller.send :after_save_url).to eq :url

      controller.class.after_save_action = :index
      expect(controller).to receive(:url_for).with(action: :index) { :url }
      expect(controller.send :after_save_url).to eq :url

      controller.class.after_save_action = :custom
      expect(controller).to receive(:url_for).
        with(action: :custom, id: :resource_obj) { :url }
      expect(controller.send :after_save_url).to eq :url
    end
  end

  describe '#after_destroy_url' do
    it 'returns url_for :index action' do
      expect(controller).to receive(:url_for).with(action: :index) { :url }
      expect(controller.send :after_destroy_url).to eq :url
    end
  end
end
