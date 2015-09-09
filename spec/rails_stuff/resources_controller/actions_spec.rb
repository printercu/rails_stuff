RSpec.describe RailsStuff::ResourcesController::Actions do
  let(:klass) { build_controller_class }
  let(:controller) { klass.new }
  let(:resource) { double }
  before do
    allow(controller).to receive_messages(
      after_save_url: :save_redirect_url,
      after_destroy_url: :destroy_redirect_url,
      resource: resource,
    )
  end

  def build_controller_class(class_name = nil)
    described_class = self.described_class
    build_named_class(class_name, ActionController::Base) do
      include RailsStuff::ResourcesController::BasicHelpers
      include described_class
    end
  end

  describe '#new' do
    it 'calls build_resource' do
      expect(controller).to receive(:build_resource)
      controller.new
    end
  end

  describe '#create' do
    before { expect(controller).to receive_messages(create_resource: create_result) }

    context 'when create succeeded' do
      let(:create_result) { true }
      it 'sets location and calls respond_with' do
        expect(controller).to receive(:respond_with).
          with(resource, option: :param, location: :save_redirect_url)
        controller.create option: :param
      end
    end

    context 'when create failed' do
      let(:create_result) { false }
      it 'calls respond_with, but doesnt set location' do
        expect(controller).to receive(:respond_with).with(resource, option: :param)
        controller.create option: :param
      end
    end
  end

  describe '#update' do
    before { expect(controller).to receive_messages(update_resource: update_result) }

    context 'when update succeeded' do
      let(:update_result) { true }
      it 'sets location and calls respond_with' do
        expect(controller).to receive(:respond_with).
          with(resource, option: :param, location: :save_redirect_url)
        controller.update option: :param
      end
    end

    context 'when update failed' do
      let(:update_result) { false }
      it 'calls respond_with, but doesnt set location' do
        expect(controller).to receive(:respond_with).with(resource, option: :param)
        controller.update option: :param
      end
    end
  end

  describe '#destroy' do
    it 'calls rsource.destroy, flash_errors! and respond_with' do
      expect(resource).to receive(:destroy)
      expect(controller).to receive_messages(flash_errors!: true)
      expect(controller).to receive(:respond_with).
        with(resource, location: :destroy_redirect_url, option: :param)
      controller.destroy(option: :param)
    end
  end
end
