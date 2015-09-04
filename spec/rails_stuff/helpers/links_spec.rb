require 'rails_helper'

RSpec.describe RailsStuff::Helpers::Links, type: :helper do
  before { allow(helper).to receive(:basic_link_icons) { icons } }
  let(:icons) { %i(destroy edit new).map { |x| [x, :"#{x}_icon"] }.to_h }

  describe '#basic_link_icon' do
    let(:icons) do
      {
        proc: -> { custom_method },
        str: 'string',
      }
    end

    before do
      def helper.custom_method
        :custom_result
      end
    end

    it 'returns string and nil as is' do
      expect(helper.basic_link_icon(:str)).to eq 'string'
      expect(helper.basic_link_icon(:string)).to eq nil
    end

    it 'executes procs' do
      expect(helper.basic_link_icon(:proc)).to eq :custom_result
    end
  end

  describe '#link_to_destroy' do
    before { helper.extend RailsStuff::Helpers::Translation }

    it 'calls link_to with specific params' do
      expect(helper).to receive(:translate_action).with(:delete) { :delete_title }
      expect(helper).to receive(:translate_confirmation).with(:delete) { :confirm_delete }
      expect(helper).to receive(:link_to).
        with(:destroy_icon, :destroy_url,
          title: :delete_title,
          method: :delete,
          data: {confirm: :confirm_delete},
          extra: :arg,
        ) { 'destroy_link_html' }
      expect(helper.link_to_destroy :destroy_url, extra: :arg).to eq 'destroy_link_html'
    end
  end

  describe '#link_to_edit' do
    before { helper.extend RailsStuff::Helpers::Translation }

    it 'calls link_to with specific params' do
      expect(helper).to receive(:translate_action).with(:edit) { :edit_title }
      expect(helper).to receive(:link_to).
        with(:edit_icon, :edit_url, title: :edit_title, extra: :arg) { 'edit_link_html' }
      expect(helper.link_to_edit :edit_url, extra: :arg).to eq 'edit_link_html'
    end
  end

  describe '#link_to_new' do
    it 'calls link_to with specific params' do
      expect(helper).to receive(:link_to).
        with(:new_icon, :new_url, extra: :arg) { 'new_link_html' }
      expect(helper.link_to_new :new_url, extra: :arg).to eq 'new_link_html'
    end
  end
end
