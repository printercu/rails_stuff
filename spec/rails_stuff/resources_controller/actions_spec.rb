RSpec.describe RailsStuff::ResourcesController::Actions do
  let(:klass) { build_controller_class }
  let(:controller) { klass.new }
  let(:resource) { double(:resource) }
  let(:block) { -> {} }
  let(:options) { {option: :param} }
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

  def expect_respond_with(*args, &block)
    expect(controller).to receive(:respond_with).with(*args) do |&blk|
      expect(blk).to be block
    end
  end

  shared_examples 'with custom location' do
    context 'and custom location is given' do
      let(:options) { super().merge(location: :my_custom_location) }
      it 'doesnt override location' do
        expect_respond_with(resource, options, &block)
        subject.call
      end
    end
  end

  describe '#new' do
    it 'calls build_resource' do
      expect(controller).to receive(:build_resource)
      controller.new
    end
  end

  describe '#create' do
    subject { -> { controller.create options.dup, &block } }
    before { expect(controller).to receive_messages(create_resource: create_result) }

    context 'when create succeeded' do
      let(:create_result) { true }
      it 'sets location and calls respond_with' do
        expect_respond_with(resource, **options, location: :save_redirect_url, &block)
        subject.call
      end

      include_examples 'with custom location'
    end

    context 'when create failed' do
      let(:create_result) { false }
      it 'calls respond_with, but doesnt set location' do
        expect_respond_with(resource, options, &block)
        subject.call
      end
    end
  end

  describe '#update' do
    subject { -> { controller.update options.dup, &block } }
    before { expect(controller).to receive_messages(update_resource: update_result) }

    context 'when update succeeded' do
      let(:update_result) { true }
      it 'sets location and calls respond_with' do
        expect_respond_with(resource, **options, location: :save_redirect_url, &block)
        subject.call
      end

      include_examples 'with custom location'
    end

    context 'when update failed' do
      let(:update_result) { false }
      it 'calls respond_with, but doesnt set location' do
        expect_respond_with(resource, options, &block)
        subject.call
      end
    end
  end

  describe '#destroy' do
    subject { -> { controller.destroy options.dup, &block } }
    before do
      expect(resource).to receive(:destroy)
      expect(controller).to receive_messages(flash_errors!: true)
    end

    it 'calls rsource.destroy, flash_errors! and respond_with' do
      expect_respond_with(resource, option: :param, location: :destroy_redirect_url, &block)
      subject.call
    end

    include_examples 'with custom location'
  end
end
