RSpec.describe RailsStuff::ResourcesController do
  describe '#resources_controller' do
    subject { ->(*args) { klass.resources_controller(*args) } }
    let(:klass) do
      described_class = self.described_class
      Class.new(ActionController::Base) { extend described_class }
    end
    let(:instance) { klass.new }

    it 'adds modules' do
      should change { klass.ancestors }.by [
        described_class::Actions,
        described_class::BasicHelpers,
      ]
    end

    it { should change { klass.responder }.to described_class::Responder }

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
      it 'sets it' do
        expect { subject.call sti: true }.to change { klass.ancestors }.by [
          described_class::Actions,
          described_class::StiHelpers,
          described_class::BasicHelpers,
        ]
      end
    end
  end
end
