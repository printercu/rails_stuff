require 'rails_helper'
require 'rails_stuff/strong_parameters'

RSpec.describe ActionController::Parameters do
  describe 'require_permitted' do
    let(:input) do
      {
        a: 1,
        b: 'str',
        c: [1, 2],
        d: '',
        e: [],
        f: {},
        g: {x: 1},
        h: nil,
      }.stringify_keys
    end
    let(:instance) { described_class.new(input) }

    it 'permits params and checks they are present' do
      expect(instance.require_permitted('a').to_h).to eq input.slice('a')
      expect(instance.require_permitted('a', 'b').to_h).to eq input.slice('a', 'b')

      ('c'..input.keys.max).each do |field|
        expect { instance.require_permitted('a', field, 'b') }.
          to raise_error(ActionController::ParameterMissing), "failed for #{input[field]}"
      end
    end
  end
end
