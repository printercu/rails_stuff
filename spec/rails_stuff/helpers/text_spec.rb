require 'rails_helper'

RSpec.describe RailsStuff::Helpers::Text, type: :helper do
  describe '#replace_blank' do
    before { expect(I18n).to receive(:t) { :blank } }
    let(:placeholder) { "<small class=\"text-muted\">(blank)</small>" }

    it 'replaces blank values with translated placeholder' do
      expect(helper.replace_blank('')).to eq placeholder
      expect(helper.replace_blank(nil)).to eq placeholder

      expect(helper.replace_blank('0')).to eq '0'
      expect(helper.replace_blank(0)).to eq 0
    end

    context 'when block is given' do
      it 'tests value & returns block`s result if value is present' do
        expect(helper.replace_blank('') { 'block' }).to eq placeholder
        expect(helper.replace_blank([]) { 'block' }).to eq placeholder
        expect(helper.replace_blank(nil) { 'block' }).to eq placeholder
        expect(helper.replace_blank(nil, &:name)).to eq placeholder

        expect(helper.replace_blank('test') { 'block' }).to eq 'block'
        expect(helper.replace_blank(1) { 'block' }).to eq 'block'
        expect(helper.replace_blank([1]) { 'block' }).to eq 'block'

        expect(helper.replace_blank(2) { |x| 'block' * x }).to eq 'blockblock'
        expect(helper.replace_blank(double(name: 'test'), &:name)).to eq 'test'
      end
    end
  end
end
