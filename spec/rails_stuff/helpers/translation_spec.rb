RSpec.describe RailsStuff::Helpers::Translation do
  let(:helper) { Object.new.tap { |x| x.extend described_class } }

  before do
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations 'en', helpers: {
      actions: {
        edit: 'edit_en',
        delete: 'delete_en',
      },
      confirmations: {
        destroy: 'destroy_en',
        clean: 'clean_en',
      },
      yes_no: {
        'true' => 'yeah',
        'false' => 'nope',
      },
    }
  end

  def self.with_i18n_raise(val)
    around do |ex|
      begin
        old_val = described_class.i18n_raise
        described_class.i18n_raise = val
        ex.run
      ensure
        described_class.i18n_raise = old_val
      end
    end
  end

  shared_examples 'raising on missing translation' do
    context 'when translation is missing' do
      let(:input) { 'missing_key' }

      context 'when .i18n_raise is true' do
        with_i18n_raise(false)
        its(:call) { should be_present }
      end

      context 'when .i18n_raise is true' do
        with_i18n_raise(true)
        it { should raise_error(I18n::MissingTranslationData) }
      end
    end
  end

  describe '#translate_action' do
    subject { ->(val = input) { helper.translate_action(val) } }
    include_examples 'raising on missing translation'

    it 'translates and caches actions' do
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(subject[:edit]).to eq 'edit_en' }
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(subject['delete']).to eq 'delete_en' }
    end
  end

  describe '#translate_confirmation' do
    subject { ->(val = input) { helper.translate_confirmation(val) } }
    include_examples 'raising on missing translation'

    it 'translates and caches confirmations' do
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(subject[:destroy]).to eq 'destroy_en' }
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(subject['clean']).to eq 'clean_en' }
    end
  end

  describe '#yes_no' do
    subject { ->(val = input) { helper.yes_no(val) } }
    include_examples 'raising on missing translation'

    it 'translates and caches boolean values' do
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(subject[true]).to eq 'yeah' }
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(subject[false]).to eq 'nope' }
    end
  end
end
