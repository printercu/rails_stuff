require 'json'
require 'active_support/core_ext/time'

Time.zone_default = Time.find_zone('UTC')

RSpec.describe RailsStuff::ParamsParser do
  describe '.parse_int' do
    subject { ->(val = input) { described_class.parse_int(val) } }

    it 'casts input to integer' do
      {
        nil     => nil,
        ''      => 0,
        'a'     => 0,
        '1'     => 1,
        '-5.5'  => -5,
      }.each do |input, expected|
        expect(subject.call(input)).to be expected
      end
    end

    context 'when input is invalid' do
      let(:input) { [] }
      it { should raise_error(described_class::Error) }
    end
  end

  describe '.parse_int_array' do
    subject { ->(val = input) { described_class.parse_int_array(val) } }

    it 'casts input to integer' do
      {
        nil => nil,
        ''  => nil,
        ['1', '2', 3, '-5.5'] => [1, 2, 3, -5],
        ['1', '2', '', '3', 'a', nil] => [1, 2, 0, 3, 0, nil],
      }.each do |input, expected|
        expect(subject.call(input)).to eq expected
      end
    end

    context 'when input is invalid' do
      let(:input) { [['1'], '1'] }
      it { should raise_error(described_class::Error) }
    end
  end

  describe '.parse_datetime' do
    subject { ->(val = input) { described_class.parse_datetime(val) } }

    context 'when argument is a string' do
      it 'parses time' do
        expect(subject.call('19:00')).to eq(Time.zone.parse('19:00'))
        expect(subject.call('01.02.2013 19:00')).to eq(Time.zone.parse('2013-02-01 19:00'))
      end

      context 'when argument is empty string' do
        let(:input) { '' }
        it { should raise_error(described_class::Error) }
      end
    end

    context 'when argument is nil' do
      let(:input) {}
      its(:call) { should be nil }
    end

    context 'when argument is not a string' do
      it 'raise error' do
        expect { subject.call([]) }.to raise_error(described_class::Error)
        expect { subject.call({}) }.to raise_error(described_class::Error)
      end
    end
  end

  describe '.parse_json' do
    subject { ->(val = input) { described_class.parse_json(val) } }

    context 'when argument is nil' do
      let(:input) {}
      its(:call) { should be nil }
    end

    context 'when argument is a string' do
      it 'parses json' do
        expect(subject.call('{"a": 1}')).to eq('a' => 1)
        expect(subject.call('[1,2]')).to eq([1, 2])
      end

      context 'when argument is empty string' do
        let(:input) { '' }
        its(:call) { should be nil }
      end

      context 'when argument is invalid json' do
        it 'raise error' do
          expect { subject.call('{') }.to raise_error(described_class::Error)
          expect { subject.call('[]]') }.to raise_error(described_class::Error)
        end
      end
    end

    context 'when argument is not a string' do
      it 'raise error' do
        expect { subject.call([1]) }.to raise_error(described_class::Error)
        expect { subject.call(a: 1) }.to raise_error(described_class::Error)
      end
    end
  end
end
