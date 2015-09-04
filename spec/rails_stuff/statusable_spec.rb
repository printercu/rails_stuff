require 'activemodel_translation/helper'
require 'support/active_record'

RSpec.describe RailsStuff::Statusable do
  let(:model) do
    described_class = self.described_class
    Class.new(ActiveRecord::Base) do
      def self.name
        'User'
      end

      extend described_class
      const_set(:STATUSES, %i(confirmed banned))
      has_status_field validate: false
      has_status_field :subscription_status, %i(pending expired),
        prefix: :subscription_
    end
  end
  let(:instance) { model.new }

  before do
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations 'en', strings: {
      status_name: {
        confirmed: 'confirmed_en',
        banned: 'banned_en',
      },
      subscription_status_name: {
        pending: 'pending_en',
        expired: 'expired_en',
      },
    }
  end

  describe '##{field}=' do
    it 'accepts symbols' do
      expect { instance.status = :confirmed }.
        to change { instance.status }.to('confirmed')
    end

    it 'accepts strings' do
      expect { instance.status = 'banned' }.
        to change { instance.status }.to('banned')
    end

    context 'for custom field' do
      it 'accepts strings' do
        expect { instance.subscription_status = 'expired' }.
          to change { instance.subscription_status }.to('expired')
      end
    end
  end

  describe '##{field}_sym' do
    it 'returns status as symbol' do
      expect { instance.status = 'banned' }.
        to change { instance.status_sym }.to(:banned)
    end

    context 'for custom field' do
      it 'returns status as symbol' do
        expect { instance.subscription_status = 'expired' }.
          to change { instance.subscription_status_sym }.to(:expired)
      end
    end
  end

  describe '.#{field}_name' do
    it 'returns translated status name' do
      expect(model.status_name(nil)).to eq(nil)
      expect(model.status_name(:confirmed)).to eq('confirmed_en')
      expect(model.status_name('banned')).to eq('banned_en')
    end

    context 'for custom field' do
      it 'returns translated status name' do
        expect(model.subscription_status_name(nil)).to eq(nil)
        expect(model.subscription_status_name(:pending)).to eq('pending_en')
        expect(model.subscription_status_name('expired')).to eq('expired_en')
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
        expect { instance.subscription_status = :expired }.
          to change { instance.subscription_status_name }.from(nil).to('expired_en')
      end
    end
  end

  describe '.#{field}_select_options' do
    it 'returns array with options for select' do
      expect(model.status_select_options).to contain_exactly(
        ['confirmed_en', :confirmed],
        ['banned_en', :banned],
      )
    end

    context 'when :except is given' do
      it 'returns only filtered items' do
        expect(model.status_select_options except: :confirmed).
          to contain_exactly ['banned_en', :banned]
      end
    end

    context 'for custom field' do
      it 'returns array with options for select' do
        expect(model.subscription_status_select_options).to contain_exactly(
          ['pending_en', :pending],
          ['expired_en', :expired],
        )
      end

      context 'when :except is given' do
        it 'returns only filtered items' do
          expect(model.subscription_status_select_options except: :pending).
            to contain_exactly ['expired_en', :expired]
        end
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
        expect { instance.subscription_status = :expired }.
          to change { instance.subscription_expired? }.from(false).to(true)
      end
    end
  end

  describe '##{status}!' do
    it 'updates field value' do
      expect(instance).to receive(:update_attributes!).with(status: 'confirmed')
      instance.confirmed!
    end

    context 'for custom field' do
      it 'updates field value' do
        expect(instance).to receive(:update_attributes!).
          with(subscription_status: 'pending')
        instance.subscription_pending!
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

  def assert_filter(*expected, &block)
    relation = block.call
    where_sql = relation.where_values.map(&:to_sql).join
    values_sql = relation.bind_values.map(&:second).join
    expect([where_sql, values_sql]).to eq(expected)
  end

  describe '.with_#{field}' do
    it 'filters records by field values' do
      assert_filter('"users"."status" = ?', 'test') { model.with_status :test }
    end

    context 'for custom field' do
      it 'filters records by field values' do
        assert_filter('"users"."subscription_status" = ?', 'test') do
          model.with_subscription_status :test
        end
      end
    end
  end

  describe '.#{status}' do
    it 'filters records by field values' do
      assert_filter('"users"."status" = ?', 'confirmed') { model.confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter('"users"."subscription_status" = ?', 'pending') do
          model.subscription_pending
        end
      end
    end
  end

  describe '.not_#{status}' do
    it 'filters records by field values' do
      assert_filter('"users"."status" != ?', 'confirmed') { model.not_confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter('"users"."subscription_status" != ?', 'pending') do
          model.not_subscription_pending
        end
      end
    end
  end
end
