RSpec.describe RailsStuff::RandomUniqAttr do
  let(:model) do
    described_class = self.described_class
    attr = self.attr
    Class.new(ActiveRecord::Base) do
      self.table_name = :tokens
      extend described_class
      random_uniq_attr attr
    end
  end
  let(:attr) { :code }

  def create_instance(attrs = {})
    model.create!(attrs)
  end

  describe '#set_#{attr}' do
    let(:other_instance) { create_instance attr => :test }
    let(:instance) { create_instance }

    context 'when instance with same generated attr value exists' do
      before do
        values = ([:test_2] + [other_instance[attr]] * 5).map(&:to_s)
        allow(other_instance.class).
          to receive("generate_#{attr}") { values.pop }.exactly(values.length).times
      end

      it 'generates new value until it is unique' do
        expect(instance[attr]).to eq('test_2')
        expect(instance.reload[attr]).to eq('test_2')
      end
    end

    it 'passes instance to generate_ method' do
      expect(instance.class).to receive("generate_#{attr}").with(instance) { 'new_val' }
      expect { instance.send "set_#{attr}" }.to change { instance[attr] }.to 'new_val'
    end
  end

  describe '.random_uniq_attr' do
    let(:klass) do
      described_class = self.described_class
      Class.new(ActiveRecord::Base) { extend described_class }
    end

    context 'when block is given' do
      let(:values) { 5.times.to_a }
      before do
        values = self.values
        klass.random_uniq_attr(:key) { values.shift }
      end

      it 'uses block as generator' do
        values.dup.each do |val|
          expect(klass.generate_key).to eq(val)
        end
      end
    end
  end
end
