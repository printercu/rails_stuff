RSpec.describe RailsStuff::Helpers::ResourceForm do
  let(:helper) { Module.new.tap { |x| x.extend described_class } }

  describe '#resource_form_for' do
    it 'compiles method without errors' do
      expect { helper.resource_form_for }.
        to change { helper.instance_methods.include?(:resource_form) }.to(true)
    end

    it 'compiles method with specified name' do
      expect { helper.resource_form_for method: :fform }.
        to change { helper.instance_methods.include?(:fform) }.to(true)
    end
  end
end
