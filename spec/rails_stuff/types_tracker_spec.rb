require 'active_record'

RSpec.describe RailsStuff::TypesTracker do
  let(:base) do
    described_class = self.described_class
    Class.new { extend described_class }
  end

  let(:child) { Class.new(base) }
  let(:grand_child) { Class.new(child) }
  let(:child_2) { Class.new(base) }

  def with_list_class(klass)
    old_klass = described_class.types_list_class
    described_class.types_list_class = klass
    yield
  ensure
    described_class.types_list_class = old_klass
  end

  # Can't do this with stubbing, 'cause class name is used before it's stubbed.
  module TypesTrackerTest
    class Project < ActiveRecord::Base
      extend RailsStuff::TypesTracker

      class Internal < self
        class Smth < self; end
      end

      class ModelName < self; end
    end
  end

  describe '#inherited' do
    it 'tracks ancestors' do
      expect(base.types_list).to contain_exactly child, grand_child, child_2
    end

    context 'when list_class is overwritten' do
      around { |ex| with_list_class(new_list_class) { ex.run } }
      let(:new_list_class) { Class.new(Array) }

      it 'tracks ancestors' do
        expect(base.types_list).to contain_exactly child, grand_child, child_2
        expect(base.types_list.class).to eq new_list_class
      end
    end
  end

  describe '#register_type' do
    it 'adds class to types_list' do
      child.unregister_type
      expect { child.register_type }.
        to change { base.types_list }.from([]).to([child])
    end

    context 'for activerecord model' do
      it 'adds scope' do
        expect(TypesTrackerTest::Project).to respond_to :internal
        expect(TypesTrackerTest::Project).to respond_to :smth
      end

      it 'doesnt override methods with scope' do
        TypesTrackerTest::Project::ModelName.register_type
        expect(TypesTrackerTest::Project.model_name).to be_instance_of ActiveModel::Name
      end
    end

    context 'when types_list has #add method' do
      around { |ex| with_list_class(new_list_class) { ex.run } }
      let(:new_list_class) do
        Class.new(Hash) do
          def add(klass, value = :default)
            self[klass] = value
          end
        end
      end

      it 'uses #add method' do
        expect { child.register_type :best }.
          to change { base.types_list }.
          from(child => :default).to(child => :best)
      end
    end
  end

  describe '#unregister_type' do
    it 'removes class from types_list' do
      expect { child.unregister_type }.
        to change { base.types_list }.
        from([child, grand_child]).to([grand_child])
    end
  end
end
