RSpec.describe RailsStuff::ResourcesController do
  describe '#resources_controller' do
    subject { ->(options = self.options) { klass.resources_controller(**options) } }
    let(:options) { {} }
    let(:klass) do
      described_class = self.described_class
      Class.new(ActionController::Base) { extend described_class }
    end
    let(:instance) { klass.new }
    let(:basic_modules) do
      [
        described_class::Actions,
        described_class::BasicHelpers,
      ]
    end

    it { should change { klass.ancestors }.by basic_modules }
    it { should_not change(klass, :responder) }

    context 'when :source_relation is given' do
      it 'overrides method' do
        subject.call source_relation: -> { :custom_source }
        expect(instance.send :source_relation).to eq :custom_source
      end
    end

    context 'when :after_save_action is given' do
      it 'sets it' do
        subject.call after_save_action: :custom_action
        expect(klass.after_save_action).to eq :custom_action
      end
    end

    context 'when :sti is true' do
      let(:options) { {sti: true} }
      let(:expected_ancestors) { basic_modules.insert(1, described_class::StiHelpers) }
      it { should change { klass.ancestors }.by expected_ancestors }
    end

    context 'when :kaminari is true' do
      let(:options) { {kaminari: true} }
      let(:expected_ancestors) { basic_modules.insert(1, described_class::KaminariHelpers) }
      it { should change { klass.ancestors }.by expected_ancestors }
    end
  end
end
