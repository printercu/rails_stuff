require 'rails_stuff/test_helpers/concurrency'

RSpec.describe RailsStuff::TestHelpers::Concurrency do
  describe '#concurrently' do
    subject { ->(*args, &block) { instance.concurrently(*args, &block) } }
    let(:instance) { Object.new.tap { |x| x.extend described_class } }
    let(:acc) { ThreadSafe::Array.new }

    context 'when no args given' do
      it 'runs block .threads_count times' do
        expect { subject.call { |i| acc << i } }.
          to change(acc, :size).from(0).to(described_class.threads_count)
        expect(acc).to eq Array.new(described_class.threads_count)
      end
    end

    context 'when arg is Integer' do
      let(:count) { 5 }
      it 'runs block arg times' do
        acc = ThreadSafe::Array.new
        expect { subject.call(count) { |i| acc << i } }.
          to change(acc, :size).from(0).to(count)
        expect(acc).to eq Array.new(count)
      end
    end

    context 'when arg is array' do
      it 'runs block for each arg' do
        input = [
          1,
          2,
          {opt: true},
          {opt: false},
          [1, opt: false],
        ]
        expect { subject.call(input) { |arg = nil, **options| acc << [arg, options] } }.
          to change(acc, :size).to(input.size)
        expect(acc).to contain_exactly  [1, {}],
                                        [2, {}],
                                        [nil, opt: true],
                                        [nil, opt: false],
                                        [1, opt: false]
      end
    end
  end
end
