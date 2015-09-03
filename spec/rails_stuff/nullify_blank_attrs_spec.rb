RSpec.describe RailsStuff::NullifyBlankAttrs do
  let(:klass) do
    described_class = self.described_class
    Class.new do
      extend described_class
      nullify_blank_attrs :nested, :own

      include(Module.new do
        attr_accessor :nested
      end)

      attr_accessor :own
    end
  end
  let(:instance) { klass.new }

  it 'nullifies blank attrs' do
    expect { instance.nested = 'test' }.to change { instance.nested }.from(nil).to('test')
    expect { instance.nested = '    ' }.to change { instance.nested }.to(nil)
  end

  it 'works with attrs defined in class' do
    expect { instance.own = 'test' }.to change { instance.own }.from(nil).to('test')
    expect { instance.own = '    ' }.to change { instance.own }.to(nil)
  end
end
