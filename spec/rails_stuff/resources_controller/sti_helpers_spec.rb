RSpec.describe RailsStuff::ResourcesController::StiHelpers do
  let(:klass) do
    build_controller_class.tap do |x|
      x.resource_class = resource_class
      x.resource_param_name = :user
    end
  end
  let(:controller) { klass.new }
  let(:resource_class) { Class.new }

  def build_controller_class(class_name = nil)
    described_class = self.described_class
    build_named_class(class_name, ActionController::Base) do
      include RailsStuff::ResourcesController::BasicHelpers
      include described_class
    end
  end

  describe '.resource_class_by_type' do
    subject { klass.resource_class_by_type }
    let(:child_1) { build_named_class :Child1, resource_class }
    let(:child_2) { build_named_class :Child2, resource_class }
    let(:grandchild) { build_named_class :Grandchild, child_1 }

    it 'is populated with resource_class descendants' do
      should eq 'Child1' => child_1, 'Child2' => child_2, 'Grandchild' => grandchild
    end

    context 'when resource_class responds to .types_list' do
      let(:resource_class) { super().tap { |x| x.extend RailsStuff::TypesTracker } }
      before { child_1.unregister_type }

      it 'is populated from types_list' do
        should eq 'Child2' => child_2, 'Grandchild' => grandchild
      end
    end
  end

  describe '#class_from_request' do
    subject { -> { controller.send :class_from_request } }
    let(:model) { Class.new }
    let(:params) { {} }
    before do
      allow_any_instance_of(klass).
        to receive(:params) { ActionController::Parameters.new(params) }
      klass.resource_class_by_type['User::Admin'] = model
    end

    context 'when valid type is requested' do
      let(:params) { {user: {type: 'User::Admin'}} }
      it 'returns mapped class for this type' do
        expect(subject.call).to eq model
      end
    end

    context 'when invalid type is requested' do
      let(:params) { {user: {type: 'Project::External'}} }
      it { should raise_error described_class::InvalidType }

      context 'when use_resource_class_for_invalid_type is true' do
        before { klass.use_resource_class_for_invalid_type = true }
        its(:call) { should eq klass.resource_class }
      end
    end

    context 'when params for resource is not given' do
      let(:params) { {project: {type: 'Project::External'}} }
      its(:call) { should eq klass.resource_class }
    end

    context 'when id is present' do
      let(:params) { {id: 1} }

      it 'takes returns resource`s class' do
        resource = Class.new.new
        expect(controller).to receive(:resource) { resource }
        expect(subject.call).to be resource.class
      end
    end
  end

  describe '.permit_attrs_for' do
    let(:other_class) { build_controller_class }
    around { |ex| expect { ex.run }.to_not change(other_class, :permitted_attrs_for) }
    around do |ex|
      expect { ex.run }.to_not change { klass.permitted_attrs_for[:other_type] }
    end

    it 'adds args to .permitted_attrs_for' do
      expect { klass.permit_attrs_for :user, :name, :lastname }.
        to change { klass.permitted_attrs_for[:user] }.
        from([]).to(%i[name lastname])
      expect { klass.permit_attrs_for :user, project_attributes: %i[id _destroy] }.
        to change { klass.permitted_attrs_for[:user] }.
        by([project_attributes: %i[id _destroy]])
    end
  end

  describe '#permitted_attrs' do
    it 'concats permitted_attrs with permitted_attrs_for specific klass' do
      model_1 = Class.new
      model_2 = Class.new
      klass.permit_attrs :name
      klass.permit_attrs_for model_1, :rule
      klass.permit_attrs_for model_2, :value

      expect(controller).to receive(:class_from_request) { model_1 }
      expect(controller.send :permitted_attrs).to contain_exactly :name, :rule

      expect(controller).to receive(:class_from_request) { model_2 }
      expect(controller.send :permitted_attrs).to contain_exactly :name, :value
    end
  end
end
