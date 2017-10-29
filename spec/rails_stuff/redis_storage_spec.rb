require 'support/redis'

RSpec.describe RailsStuff::RedisStorage do
  let(:model) do
    described_class = self.described_class
    Class.new do
      extend described_class
      self.redis_prefix = :rails_stuff_test
    end
  end
  let(:prefix) { model.redis_prefix }

  let(:parent) do
    described_class = self.described_class
    Class.new { extend described_class }
  end
  let(:child) { Class.new(parent) }
  let(:redis) { parent.redis_pool.simple_connection }

  describe '#redis_set_options' do
    it 'inherits value from parent' do
      parent_val = {a: 1}
      child_val = {b: 2}

      expect(parent.redis_set_options).to eq({})
      expect(child.redis_set_options).to eq({})

      parent.redis_set_options = parent_val
      expect(parent.redis_set_options).to eq(parent_val)
      expect(child.redis_set_options).to eq(parent_val)

      child.redis_set_options = child_val
      expect(parent.redis_set_options).to eq(parent_val)
      expect(child.redis_set_options).to eq(child_val)
    end
  end

  describe '#redis_key_for' do
    it 'works with scalars' do
      expect(model.redis_key_for(1)).to eq "#{prefix}:1"
      expect(model.redis_key_for(nil)).to eq "#{prefix}:"
      expect(model.redis_key_for('test')).to eq "#{prefix}:test"
      model.redis_prefix = :test_2
      expect(model.redis_key_for(1)).to eq 'test_2:1'
    end

    it 'works with array' do
      expect(model.redis_key_for([])).to eq "#{prefix}:"
      expect(model.redis_key_for([1, 2])).to eq "#{prefix}:1:2"
      expect(model.redis_key_for([1, nil, 2])).to eq "#{prefix}:1::2"
      expect(model.redis_key_for(['test', :a])).to eq "#{prefix}:test:a"
      model.redis_prefix = :test_2
      expect(model.redis_key_for([1, 2])).to eq 'test_2:1:2'
    end
  end

  describe '#redis_id_seq_key' do
    it 'works with scalars' do
      expect(model.redis_id_seq_key).to eq "#{prefix}_id_seq"
      expect(model.redis_id_seq_key(nil)).to eq "#{prefix}_id_seq"
      expect(model.redis_id_seq_key('test')).to eq "#{prefix}_id_seq:test"
      model.redis_prefix = :test_2
      expect(model.redis_id_seq_key(1)).to eq 'test_2_id_seq:1'
    end

    it 'works with array' do
      expect(model.redis_id_seq_key([])).to eq "#{prefix}_id_seq"
      expect(model.redis_id_seq_key([1, 2])).to eq "#{prefix}_id_seq:1:2"
      expect(model.redis_id_seq_key([1, nil, 2])).to eq "#{prefix}_id_seq:1::2"
      expect(model.redis_id_seq_key(['test', :a])).to eq "#{prefix}_id_seq:test:a"
      model.redis_prefix = :test_2
      expect(model.redis_id_seq_key([1, 2])).to eq 'test_2_id_seq:1:2'
    end
  end

  describe '#reset_id_seq' do
    it 'deletes counter' do
      redis.set("#{prefix}_id_seq", 1)
      redis.set("#{prefix}_id_seq:1:2", 1)

      expect { model.reset_id_seq }.
        to change { redis.get("#{prefix}_id_seq") }.to(nil)
      expect { model.reset_id_seq([1, 2]) }.
        to change { redis.get("#{prefix}_id_seq:1:2") }.to(nil)
    end
  end

  describe '#next_id' do
    it 'returns sequental numbers' do
      redis.del("#{prefix}_id_seq")
      redis.del("#{prefix}_id_seq:1:2")

      {
        1 => nil,
        2 => 1,
      }.each do |next_val, prev_val|
        expect { expect(model.next_id).to eq(next_val) }.
          to change { redis.get("#{prefix}_id_seq").try(:to_i) }.
          from(prev_val).to(next_val)

        expect { expect(model.next_id([1, 2])).to eq(next_val) }.
          to change { redis.get("#{prefix}_id_seq:1:2").try(:to_i) }.
          from(prev_val).to(next_val)
      end
    end
  end

  describe '#set' do
    context 'when id is nil' do
      it 'generates new id for the record' do
        model.reset_id_seq
        redis.del("#{prefix}:1")
        redis.del("#{prefix}:2")

        expect do
          expect { expect(model.set(nil, :test)).to eq(1) }.
            to change { redis.get("#{prefix}_id_seq").try(:to_i) }.from(nil).to(1)
        end.to change { redis.get("#{prefix}:1") }.from(nil)
        expect do
          expect { expect(model.set([], :test)).to eq(2) }.
            to change { redis.get("#{prefix}_id_seq").try(:to_i) }.from(1).to(2)
        end.to change { redis.get("#{prefix}:2") }.from(nil)
      end

      context 'for scoped key' do
        it 'generates new id for the record' do
          model.reset_id_seq(%i[a b])
          redis.del("#{prefix}:a:b:1")

          expect do
            expect { expect(model.set([:a, :b, nil], :test)).to eq(1) }.
              to change { redis.get("#{prefix}_id_seq:a:b").try(:to_i) }.from(nil).to(1)
          end.to change { redis.get("#{prefix}:a:b:1") }.from(nil)
        end
      end
    end

    context 'when id is not nil' do
      it 'updates value' do
        redis.set("#{prefix}:1", 1)
        redis.set("#{prefix}:a:b:1", 1)

        expect { model.set(1, 2) }.to change { redis.get("#{prefix}:1") }.from('1')
        expect { model.set([:a, :b, 1], 2) }.
          to change { redis.get("#{prefix}:a:b:1") }.from('1')
      end
    end
  end

  describe '#delete' do
    it 'removes key' do
      redis.set("#{prefix}:1", 1)
      redis.set("#{prefix}:a:b:1", 1)

      expect { model.delete(1) }.
        to change { redis.get("#{prefix}:1") }.from('1').to(nil)
      expect { model.delete([:a, :b, 1]) }.
        to change { redis.get("#{prefix}:a:b:1") }.from('1').to(nil)
    end
  end

  describe '#get' do
    it 'returns saved value' do
      model.set(1, test: 1)
      expect(model.get(1)).to eq(test: 1)
      model.set([:a, :b, 2], test: 2)
      expect(model.get([:a, :b, 2])).to eq(test: 2)
    end
  end
end
