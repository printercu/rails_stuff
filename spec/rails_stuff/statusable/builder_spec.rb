require 'support/shared/statusable'

RSpec.describe RailsStuff::Statusable, :db_cleaner do
  include_context 'statusable'

  let(:model) do
    described_class = self.described_class
    build_named_class :Customer, ActiveRecord::Base do
      extend described_class
      const_set(:STATUSES, %i[confirmed banned])
      has_status_field validate: false
      has_status_field :subscription_status, %i[pending expired],
        prefix: :subscription_
    end
  end
  before do
    add_translations(
      status: %w[confirmed banned],
      subscription_status: %w[pending expired],
    )
  end

  describe '##{field}=' do
    it 'accepts symbols' do
      expect { instance.status = :confirmed }.
        to change(instance, :status).from(nil).to('confirmed')
    end

    it 'accepts strings' do
      expect { instance.status = 'banned' }.
        to change(instance, :status).from(nil).to('banned')
    end

    context 'for custom field' do
      it 'accepts strings and symbols' do
        expect { instance.subscription_status = 'expired' }.
          to change(instance, :subscription_status).from(nil).to('expired')
        expect { instance.subscription_status = :pending }.
          to change(instance, :subscription_status).to('pending')
      end
    end
  end

  describe '##{field}_sym' do
    it 'returns status as symbol' do
      expect { instance.status = 'banned' }.
        to change(instance, :status_sym).from(nil).to(:banned)
    end

    context 'for custom field' do
      it 'returns status as symbol' do
        expect { instance.subscription_status = 'expired' }.
          to change(instance, :subscription_status_sym).from(nil).to(:expired)
      end
    end
  end

  describe '##{status}?' do
    it 'checks status' do
      expect { instance.status = :confirmed }.
        to change(instance, :confirmed?).from(false).to(true)
    end

    context 'for custom field' do
      it 'checks status' do
        expect { instance.subscription_status = :expired }.
          to change(instance, :subscription_expired?).from(false).to(true)
      end
    end
  end

  describe '##{status}!' do
    it 'updates field value' do
      expect(instance).to receive(:update!).with(status: 'confirmed')
      instance.confirmed!
    end

    context 'for custom field' do
      it 'updates field value' do
        expect(instance).to receive(:update!).
          with(subscription_status: 'pending')
        instance.subscription_pending!
      end
    end
  end

  describe '##{field}_name' do
    it 'returns translated status name' do
      expect { instance.status = :confirmed }.
        to change(instance, :status_name).from(nil).to('confirmed_en')
    end

    context 'for custom field' do
      it 'returns translated status name' do
        expect { instance.subscription_status = :expired }.
          to change(instance, :subscription_status_name).from(nil).to('expired_en')
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
          to change { instance.errors[:subscription_status] }.from []
        instance.subscription_status = :invalid
        expect { instance.valid? }.
          to_not change { instance.errors[:subscription_status] }
        instance.subscription_status = :pending
        expect { instance.valid? }.
          to change { instance.errors[:subscription_status] }.to([])
      end
    end
  end

  describe '.with_#{field}' do
    it 'filters records by field values' do
      assert_filter(-> { where(status: :test) }) { with_status :test }
      assert_filter(-> { where(status: %i[test test2]) }) { with_status %i[test test2] }
    end

    context 'for custom field' do
      it 'filters records by field values' do
        assert_filter(-> { where(subscription_status: :test) }) { with_subscription_status :test }
        assert_filter(-> { where(subscription_status: %i[test test2]) }) do
          with_subscription_status %i[test test2]
        end
      end
    end
  end

  describe '.#{status}' do
    it 'filters records by field values' do
      assert_filter(-> { where(status: :confirmed) }) { confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter(-> { where(subscription_status: :pending) }) { subscription_pending }
      end
    end
  end

  describe '.not_#{status}' do
    it 'filters records by field values' do
      assert_filter(-> { where.not(status: :confirmed) }) { not_confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter(-> { where.not(subscription_status: :pending) }) { not_subscription_pending }
      end
    end
  end
end
