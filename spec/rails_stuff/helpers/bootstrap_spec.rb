RSpec.describe RailsStuff::Helpers::Bootstrap, type: :helper do
  describe '#basic_link_icons' do
    context 'when used with Helper::Links' do
      let(:helper) do
        Object.tap { |x| x.extend RailsStuff::Helpers::Links }.
          tap { |x| x.extend described_class }
      end

      it 'returns glyphicons' do
        expect(helper.basic_link_icon(:edit)).to include('glyphicon')
      end
    end
  end
end
