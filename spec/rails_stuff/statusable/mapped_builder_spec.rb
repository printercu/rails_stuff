require 'support/shared/statusable'

RSpec.describe RailsStuff::Statusable, :db_cleaner do
  include_context 'statusable'

  let(:model) do
    described_class = self.described_class
    build_named_class :Order, ActiveRecord::Base do
      extend described_class
      const_set(:STATUSES_MAPPING, confirmed: 1, rejected: 3)
      has_status_field validate: false
      has_status_field :delivery_status, {sent: 1, complete: 4},
        prefix: :delivery_
      has_status_field :delivery_method, {pickup: 1, local: 2, international: 3},
        suffix: :_delivery
    end
  end
  before do
    add_translations(
      status: %w(confirmed rejected),
      delivery_status: %w(sent complete),
      delivery_method: %w(pickup local international),
    )
  end

  describe '##{field}' do
    shared_examples 'two readers' do |mapped, original|
      its(:call) { should eq mapped }
      context 'when arg is true' do
        let(:args) { [true] }
        its(:call) { should eq original }
      end
    end

    shared_examples 'field reader' do |field, value|
      subject { -> { instance.public_send(field, *args) } }
      let(:args) { [] }
      include_examples 'two readers', nil, nil

      context 'when value is set' do
        before { instance[field] = 1 }
        include_examples 'two readers', value, 1

        context 'when value is invalid' do
          before { instance[field] = -1 }
          include_examples 'two readers', -1, -1
        end
      end
    end

    include_examples 'field reader', :status, :confirmed

    context 'for custom field' do
      include_examples 'field reader', :delivery_status, :sent
    end
  end

  describe '##{field}=' do
    shared_examples 'field writer' do |field, value|
      subject { ->(val) { instance.public_send("#{field}=", val) } }

      it 'accepts symbols' do
        expect { subject[value] }.to change { instance[field] }.to(1)
        expect { subject[:invalid] }.to change { instance[field] }.to(0)
      end

      it 'accepts strings' do
        expect { subject[value] }.to change { instance[field] }.to(1)
        expect { subject['invalid'] }.to change { instance[field] }.to(0)
      end

      it 'accepts all types' do
        expect { subject[55] }.to change { instance[field] }.to(55)
        expect { subject[nil] }.to change { instance[field] }.to(nil)
      end
    end

    include_examples 'field writer', :status, :confirmed

    context 'for custom field' do
      include_examples 'field writer', :delivery_status, :sent
    end
  end

  describe '##{field}_sym' do
    it 'returns status as symbol' do
      expect { instance.status = 'rejected' }.
        to change(instance, :status_sym).from(nil).to(:rejected)
    end

    context 'for custom field' do
      it 'returns status as symbol' do
        expect { instance.delivery_status = 'complete' }.
          to change(instance, :delivery_status_sym).from(nil).to(:complete)
      end
    end
  end

  describe '##{field}_name' do
    it 'returns translated status name' do
      expect { instance.status = :confirmed }.
        to change { instance.status_name }.from(nil).to('confirmed_en')
    end

    context 'for custom field' do
      it 'returns translated status name' do
        expect { instance.delivery_status = :complete }.
          to change { instance.delivery_status_name }.from(nil).to('complete_en')
      end
    end
  end

  describe '##{status}?' do
    it 'checks status' do
      expect { instance.status = :confirmed }.
        to change { instance.confirmed? }.from(false).to(true)
    end

    context 'for custom field' do
      it 'checks status' do
        expect { instance.delivery_status = :complete }.
          to change { instance.delivery_complete? }.from(false).to(true)
      end
    end

    context 'with suffix' do
      it 'checks status' do
        expect { instance.delivery_method = :local }.
          to change { instance.local_delivery? }.from(false).to(true)
      end
    end
  end

  describe '##{status}!' do
    it 'updates field value' do
      expect(instance).to receive(:update!).with(status: 1)
      instance.confirmed!
    end

    context 'for custom field' do
      it 'updates field value' do
        expect(instance).to receive(:update!).with(delivery_status: 1)
        instance.delivery_sent!
      end
    end

    context 'with suffix' do
      it 'updates field value' do
        expect(instance).to receive(:update!).with(delivery_method: 2)
        instance.local_delivery!
      end
    end
  end

  describe 'validations' do
    context 'when validate: false' do
      it 'skips validations' do
        expect { instance.valid? }.to_not change { instance.errors[:status] }.from []
        instance.status = :invalid
        expect { instance.valid? }.to_not change { instance.errors[:status] }.from []
      end
    end

    context 'for custom field' do
      it 'checks valid value' do
        expect { instance.valid? }.
          to change { instance.errors[:delivery_status] }.from []
        instance.delivery_status = :invalid
        expect { instance.valid? }.
          to_not change { instance.errors[:delivery_status] }
        instance.delivery_status = :sent
        expect { instance.valid? }.
          to change { instance.errors[:delivery_status] }.to([])
      end
    end
  end

  describe '.with_#{field}' do
    it 'filters records by field values' do
      assert_filter(-> { where(status: 1) }) { with_status :confirmed }
      assert_filter(-> { where(status: 3) }) { with_status 'rejected' }
      assert_filter(-> { where(status: 5) }) { with_status 5 }
      assert_filter(-> { where(status: [1, 5]) }) { with_status [1, 5] }
    end

    context 'for custom field' do
      it 'filters records by field values' do
        assert_filter(-> { where(delivery_status: 1) }) { with_delivery_status :sent }
        assert_filter(-> { where(delivery_status: 4) }) { with_delivery_status 'complete' }
        assert_filter(-> { where(delivery_status: 5) }) { with_delivery_status 5 }
        assert_filter(-> { where(delivery_status: [1, 5]) }) { with_delivery_status [1, 5] }
      end
    end
  end

  describe '.#{status}' do
    it 'filters records by field values' do
      assert_filter(-> { where(status: 1) }) { confirmed }
      assert_filter(-> { where(status: 3) }) { rejected }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter(-> { where(delivery_status: 1) }) { delivery_sent }
        assert_filter(-> { where(delivery_status: 4) }) { delivery_complete }
      end
    end

    context 'for status with suffix' do
      it 'filters records by field value' do
        assert_filter(-> { where(delivery_method: 1) }) { pickup_delivery }
        assert_filter(-> { where(delivery_method: 3) }) { international_delivery }
      end
    end
  end

  describe '.not_#{status}' do
    it 'filters records by field values' do
      assert_filter(-> { where.not(status: 1) }) { not_confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter(-> { where.not(delivery_status: 1) }) { not_delivery_sent }
      end
    end

    context 'for status with suffix' do
      it 'filters records by field value' do
        assert_filter(-> { where.not(delivery_method: 1) }) { not_pickup_delivery }
      end
    end
  end
end
