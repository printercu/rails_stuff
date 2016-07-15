require 'integration_helper'

RSpec.describe RailsStuff::AssociationWriter, :db_cleaner do
  let(:klass) do
    described_class = self.described_class
    build_named_class(:Project, ActiveRecord::Base) do
      belongs_to :user
      extend described_class
      attr_reader :username

      association_writer :user do |val|
        super(val).tap { @username = user.try!(:name) }
      end
    end
  end
  let(:instance) { klass.new }

  describe 'updating by id' do
    subject { -> { instance.user_id = new_val } }
    let(:new_val) { user.id }
    let(:user) { User.create_default! }
    it { should change(instance, :username).to(user.name) }
    it { should change(instance, :user).to(user) }
    its(:call) { should eq new_val }

    context 'when invalid id is given' do
      let(:new_val) { -1 }
      it { should_not change(instance, :username).from(nil) }
      it { should_not change(instance, :user).from(nil) }
      its(:call) { should eq new_val }
    end
  end

  describe 'updating with object' do
    subject { -> { instance.user = new_val } }
    let(:new_val) { user }
    let(:user) { User.create_default! }
    it { should change(instance, :username).to(user.name) }
    it { should change(instance, :user).to(user) }
    its(:call) { should eq new_val }

    context 'when nil is given' do
      let(:new_val) {}
      it { should_not change(instance, :username).from(nil) }
      it { should_not change(instance, :user).from(nil) }
      its(:call) { should eq new_val }
    end
  end
end
