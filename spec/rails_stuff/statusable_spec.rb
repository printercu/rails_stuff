require 'support/shared/statusable'

RSpec.describe RailsStuff::Statusable, :db_cleaner do
  include_context 'statusable'

  let(:model) do
    build_named_class :Customer, ActiveRecord::Base do
      extend RailsStuff::Statusable
    end
  end

  describe '.has_status_field' do
    subject { -> { model.has_status_field :field, %i[a b], options, &block } }
    let(:options) { {} }
    let(:block) {}
    it { should change { model.ancestors.size }.by(1) }
    it { should change(model, :instance_methods) }
    it { should change(model, :public_methods) }

    context 'for second field' do
      before { model.has_status_field :field_2, %i[c d] }
      it { should_not change { model.ancestors.size } }
    end

    context 'when block is given' do
      let(:block) { ->(x) { x.field_scope } }
      it { should_not change(model, :instance_methods) }
      it { should change { model.respond_to?(:with_field) }.from(false).to(true) }
    end

    context 'when builder is false' do
      let(:options) { {builder: false} }
      it { should_not change(model, :instance_methods) }
      it { should change(model, :public_methods).by([:fields]) }
    end
  end
end
