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

  describe '#translate_action' do
    it 'translates and caches actions' do
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(helper.translate_action :edit).to eq 'edit_en' }
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(helper.translate_action 'delete').to eq 'delete_en' }
    end
  end

  describe '#translate_confirmation' do
    it 'translates and caches confirmations' do
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(helper.translate_confirmation :destroy).to eq 'destroy_en' }
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(helper.translate_confirmation 'clean').to eq 'clean_en' }
    end
  end

  describe '#yes_no' do
    it 'translates and caches boolean values' do
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(helper.yes_no true).to eq 'yeah' }
      expect(I18n).to receive(:t).once.and_call_original
      2.times { expect(helper.yes_no false).to eq 'nope' }
    end
  end
end
