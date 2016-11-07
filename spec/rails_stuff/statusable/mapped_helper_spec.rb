require 'support/shared/statusable'

RSpec.describe RailsStuff::Statusable::MappedHelper, :db_cleaner do
  include_context 'statusable'

  subject { instance }
  let(:instance) { model.statuses }
  let(:statuses) { {confirmed: 1, rejected: 3} }
  let(:model) do
    statuses = self.statuses
    build_named_class :Customer, ActiveRecord::Base do
      extend RailsStuff::Statusable
      has_status_field :status, statuses, validate: false
    end
  end
  before { add_translations(status: %w(confirmed rejected)) }

  its(:list) { should eq statuses.keys }
  its(:list) { should be_frozen }

  its(:mapping) { should eq statuses }
  its(:mapping) { should be_frozen }

  its(:inverse_mapping) { should eq statuses.invert }
  its(:inverse_mapping) { should be_frozen }

  describe '#select_options' do
    subject { ->(*args) { instance.select_options(*args) } }

    it 'returns array for options_for_select' do
      expect(subject.call).to contain_exactly(
        ['confirmed_en', :confirmed],
        ['rejected_en', :rejected],
      )
      expect(subject[except: [:confirmed]]).to contain_exactly ['rejected_en', :rejected]
      expect(subject[only: [:confirmed]]).to contain_exactly ['confirmed_en', :confirmed]
    end

    context 'when :original is true' do
      subject { ->(**options) { instance.select_options(**options, original: true) } }
      it 'uses db values instead of mapped' do
        expect(subject.call).to contain_exactly(
          ['confirmed_en', 1],
          ['rejected_en', 3],
        )
        expect(subject[except: [1]]).to contain_exactly ['rejected_en', 3]
        expect(subject[only: [1]]).to contain_exactly ['confirmed_en', 1]
      end
    end
  end

  describe '#map' do
    subject { ->(val) { instance.map(val) } }

    it 'maps single value' do
      expect(subject[:confirmed]).to eq 1
      expect(subject[:rejected]).to eq 3
      expect(subject['rejected']).to eq 3
      expect(subject[:missing]).to eq :missing
      expect(subject[nil]).to eq nil
    end

    it 'maps array' do
      expect(subject[[:confirmed, :rejected, 'rejected', :missing, nil]]).
        to eq [1, 3, 3, :missing, nil]
    end
  end

  describe '#unmap' do
    subject { ->(val) { instance.unmap(val) } }

    it 'maps single value' do
      expect(subject[1]).to eq :confirmed
      expect(subject[3]).to eq :rejected
      expect(subject[:missing]).to eq :missing
      expect(subject[nil]).to eq nil
    end

    it 'maps array' do
      expect(subject[[1, 3, :missing, nil]]).to eq [:confirmed, :rejected, :missing, nil]
    end
  end
end
