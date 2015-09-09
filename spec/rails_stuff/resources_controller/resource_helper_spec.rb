RSpec.describe RailsStuff::ResourcesController::ResourceHelper do
  let(:klass) do
    described_class = self.described_class
    Class.new(ActionController::Base) { extend described_class }
  end
  let(:params) { {user_id: 1, secret_id: 2, admin_user_id: 3} }
  let(:controller) do
    klass.new.tap do |x|
      allow(x).to receive(:params) { ActionController::Parameters.new(params) }
    end
  end

  describe '#resource_helper' do
    subject { ->(*args) { klass.resource_helper(*args) } }

    def assert_generated_method(method, class_name, param, options = {}) #
      expect(klass).to receive(:helper_method).with(method)
      expect { klass.resource_helper method, options }.
        to change { klass.protected_instance_methods }.by [method]
      assert_finder_method(method, class_name, param)
    end

    def assert_finder_method(method, class_name, param)
      model = double
      stub_const(class_name.to_s, model)
      expect(model).to receive(:find).with(params[param]) { :found_user }
      expect(controller.send(method)).to eq :found_user
    end

    it 'defines resource accessor and calls helper_method' do
      assert_generated_method(:user, :User, :user_id)
    end

    context 'when :class is given' do
      it 'defines resource accessor for given class' do
        assert_generated_method(:admin_user, :Admin, :admin_user_id, class: :Admin)
      end
    end

    context 'when :param is given' do
      it 'defines resource accessor using given param' do
        assert_generated_method(:user, :User, :secret_id, param: :secret_id)
      end
    end
  end
end
