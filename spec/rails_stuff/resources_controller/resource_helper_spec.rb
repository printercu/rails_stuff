RSpec.describe RailsStuff::ResourcesController::ResourceHelper do
  let(:klass) do
    described_class = self.described_class
    Class.new(ActionController::Base) { extend described_class }
  end
  let(:params) { {user_id: 1, secret_id: 2, admin_user_id: 3} }
  let(:controller) do
    params = ActionController::Parameters.new(self.params)
    klass.new.tap { |x| allow(x).to receive(:params) { params } }
  end

  describe '#resource_helper' do
    subject { -> { klass.resource_helper(method, options) } }
    let(:method) { :user }
    let(:options) { {} }
    let(:model_name) { :User }
    let!(:model) { stub_const(model_name.to_s, double(:model)) }

    shared_examples 'helper methods' do
      it 'generates helper methods' do
        expected_methods = [method, :"#{method}?"]
        expect(klass).to receive(:helper_method).with(*expected_methods)
        should change { klass.protected_instance_methods.sort }.by(expected_methods)
      end
    end

    shared_examples 'finder method' do |param|
      it 'generates finder method' do
        subject.call
        expect(model).to receive(:find).with(params[param]) { :found_user }
        expect do
          expect(controller.send(method)).to eq :found_user
        end.to change { controller.instance_variable_get("@#{method}") }.from(nil).to(:found_user)
        # assert cache
        expect(model).to_not receive(:find)
        expect(controller.send(method)).to eq :found_user
      end
    end

    shared_examples 'enquirer method' do |param|
      it 'generates enquirer method' do
        subject.call
        expect(controller.params).to receive(:key?).with(param) { :key_result }
        expect(controller.send("#{method}?")).to eq :key_result
      end
    end

    include_examples 'helper methods'
    include_examples 'finder method', :user_id
    include_examples 'enquirer method', :user_id

    context 'when :class is given' do
      let(:method) { :admin_user }
      let(:options) { {class: :Admin} }
      let(:model_name) { :Admin }
      around { |ex| described_class.deprecation.silence { ex.run } }
      include_examples 'finder method', :admin_user_id
    end

    context 'when :source is given' do
      let(:method) { :admin_user }
      let(:options) { {source: :Admin} }
      let(:model_name) { :Admin }
      include_examples 'helper methods'
      include_examples 'finder method', :admin_user_id
      include_examples 'enquirer method', :admin_user_id

      context 'with class' do
        let(:options) { {source: -> { get_source }} }
        let(:options) { {source: model} }
        let(:model) { Class.new { def self.find(*); end } }
        include_examples 'finder method', :admin_user_id
      end

      context 'with block' do
        let(:options) { {source: -> { get_source }} }
        let(:model) { double(:model).tap { |x| klass.send(:define_method, :get_source) { x } } }
        include_examples 'finder method', :admin_user_id
      end
    end

    context 'when :param is given' do
      let(:options) { {param: :secret_id} }
      include_examples 'helper methods'
      include_examples 'finder method', :secret_id
      include_examples 'enquirer method', :secret_id
    end
  end
end
