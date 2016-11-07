require 'support/shared/statusable'

RSpec.describe RailsStuff::Statusable::Helper, :db_cleaner do
  include_context 'statusable'

  subject { instance }
  let(:instance) { model.statuses }
  let(:statuses) { %i(confirmed banned) }
  let(:model) do
    statuses = self.statuses
    build_named_class :Customer, ActiveRecord::Base do
      extend RailsStuff::Statusable
      has_status_field :status, statuses, validate: false
    end
  end
  before { add_translations(status: %w(confirmed banned)) }

  its(:list) { should eq statuses }
  its(:list) { should be_frozen }

  describe '#translate' do
    subject { ->(val) { instance.translate(val) } }

    it 'returns translated status name' do
      expect(subject[nil]).to eq(nil)
      expect(subject[:confirmed]).to eq('confirmed_en')
      expect(subject['banned']).to eq('banned_en')
    end
  end

  describe '#select_options' do
    subject { ->(*args) { instance.select_options(*args) } }

    it 'returns array for options_for_select' do
      expect(subject.call).to contain_exactly(
        ['confirmed_en', :confirmed],
        ['banned_en', :banned],
      )
      expect(subject[except: [:confirmed]]).to contain_exactly ['banned_en', :banned]
      expect(subject[only: [:confirmed]]).to contain_exactly ['confirmed_en', :confirmed]
    end
  end
end
