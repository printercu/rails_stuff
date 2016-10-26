require 'support/shared/statusable'

RSpec.describe RailsStuff::Statusable, :db_cleaner do
  include_context 'statusable'

  let(:model) do
    build_named_class :Customer, ActiveRecord::Base do
      extend RailsStuff::Statusable
    end
  end

  describe '.has_status_field' do
    subject { -> { model.has_status_field :field, [:a, :b] } }
    it { should change { model.ancestors.size }.by(1) }

    context 'for second field' do
      before { model.has_status_field :field_2, [:c, :d] }
      it { should_not change { model.ancestors.size } }
    end
  end
end
