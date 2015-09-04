require 'rails_helper'

RSpec.describe RailsStuff::Helpers::Forms, type: :helper do
  describe '#hidden_params_fields' do
    before do
      params.merge!(
        str_1: 'val_1',
        str_2: '',
        ar_1: %w(val_1_1 val_1_2),
        ar_2: %w(val_2),
        ar_3: [],
        ar_4: [''],
        null: nil,
      )
    end

    def assert_inputs(fields, expected)
      html = helper.hidden_params_fields(*fields)
      result = Nokogiri::HTML.fragment(html).children.
        map { |x| [x.attr(:name), x.attr(:value)] }
      expect(result).to contain_exactly(*expected)
    end

    it 'works for scalar values' do
      assert_inputs [:str_1, :str_2], [%w(str_1 val_1), ['str_2', '']]
      assert_inputs [:str_1, :str_3], [%w(str_1 val_1)]
      assert_inputs [:str_1, :null], [%w(str_1 val_1), ['null', nil]]
    end

    it 'works for array' do
      assert_inputs [:ar_1, :ar_2],
        [%w(ar_1[] val_1_1), %w(ar_1[] val_1_2), %w(ar_2[] val_2)]
      assert_inputs [:ar_2, :ar_3], [%w(ar_2[] val_2)]
      assert_inputs [:ar_4], [['ar_4[]', '']]
    end
  end
end
