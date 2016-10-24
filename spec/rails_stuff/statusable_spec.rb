require 'activemodel_translation/helper'
require 'support/active_record'

RSpec.describe RailsStuff::Statusable, :db_cleaner do
  let(:model) do
    described_class = self.described_class
    build_named_class :Customer, ActiveRecord::Base do
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
        rejected: 'rejected_en',
      },
      subscription_status_name: {
        pending: 'pending_en',
        expired: 'expired_en',
      },
      delivery_status_name: {
        sent: 'sent_en',
        complete: 'complete_en',
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

  def assert_filter(*expected)
    relation = yield
    where_sql = relation.where_values.map(&:to_sql).join
    values_sql = relation.bind_values.map(&:second).join
    expect([where_sql, values_sql]).to eq(expected)
  end

  describe '.with_#{field}' do
    it 'filters records by field values' do
      assert_filter('"customers"."status" = ?', 'test') { model.with_status :test }
      assert_filter('"customers"."status" IN (\'test\', \'test2\')', '') do
        model.with_status [:test, :test2]
      end
    end

    context 'for custom field' do
      it 'filters records by field values' do
        assert_filter('"customers"."subscription_status" = ?', 'test') do
          model.with_subscription_status :test
        end
        assert_filter('"customers"."subscription_status" IN (\'test\', \'test2\')', '') do
          model.with_subscription_status [:test, :test2]
        end
      end
    end
  end

  describe '.#{status}' do
    it 'filters records by field values' do
      assert_filter('"customers"."status" = ?', 'confirmed') { model.confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter('"customers"."subscription_status" = ?', 'pending') do
          model.subscription_pending
        end
      end
    end
  end

  describe '.not_#{status}' do
    it 'filters records by field values' do
      assert_filter('"customers"."status" != ?', 'confirmed') { model.not_confirmed }
    end

    context 'for status with prefix' do
      it 'filters records by field value' do
        assert_filter('"customers"."subscription_status" != ?', 'pending') do
          model.not_subscription_pending
        end
      end
    end
  end

  context 'when using with mapping' do
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

    describe '##{field}' do
      it 'accepts symbols' do
        expect { instance.status = 1 }.to change { instance.status(true) }.to('confirmed')
        expect(instance.status).to eq(1)
      end

      it 'raises error when value can not be mapped' do
        expect { instance.status = 2 }.to change { instance.status }.to(2)
        expect { instance.status(true) }.to raise_error(/Missing/)
      end

      context 'for custom field' do
        it 'accepts strings' do
          expect { instance.delivery_status = 1 }.
            to change { instance.delivery_status(true) }.to('sent')
          expect(instance.delivery_status).to eq(1)
        end
      end
    end

    describe '##{field}=' do
      it 'accepts symbols' do
        expect { instance.status = :confirmed }.to change { instance[:status] }.to(1)
        expect { instance.status = :invalid }.to change { instance[:status] }.to(0)
      end

      it 'accepts strings' do
        expect { instance.status = 'rejected' }.to change { instance[:status] }.to(3)
        expect { instance.status = 'invalid' }.to change { instance[:status] }.to(0)
      end

      it 'accepts all types' do
        expect { instance.status = 55 }.to change { instance[:status] }.to(55)
        expect { instance.status = nil }.to change { instance[:status] }.to(nil)
      end

      context 'for custom field' do
        it 'accepts strings' do
          expect { instance.delivery_status = 'complete' }.
            to change { instance[:delivery_status] }.to(4)
        end
      end
    end

    describe '##{field}_sym' do
      it 'returns status as symbol' do
        expect { instance.status = 'rejected' }.
          to change { instance.status_sym }.to(:rejected)
      end

      context 'for custom field' do
        it 'returns status as symbol' do
          expect { instance.delivery_status = 'complete' }.
            to change { instance.delivery_status_sym }.to(:complete)
        end
      end
    end

    describe '.#{field}_name' do
      it 'returns translated status name' do
        expect(model.status_name(nil)).to eq(nil)
        expect(model.status_name(:confirmed)).to eq('confirmed_en')
        expect(model.status_name('rejected')).to eq('rejected_en')
      end

      context 'for custom field' do
        it 'returns translated status name' do
          expect(model.delivery_status_name(nil)).to eq(nil)
          expect(model.delivery_status_name(:sent)).to eq('sent_en')
          expect(model.delivery_status_name('complete')).to eq('complete_en')
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

    describe '.#{field}_select_options' do
      it 'returns array with options for select' do
        expect(model.status_select_options).to contain_exactly(
          ['confirmed_en', :confirmed],
          ['rejected_en', :rejected],
        )
      end

      context 'when :except is given' do
        it 'returns only filtered items' do
          expect(model.status_select_options except: :confirmed).
            to contain_exactly ['rejected_en', :rejected]
        end
      end

      context 'for custom field' do
        it 'returns array with options for select' do
          expect(model.delivery_status_select_options).to contain_exactly(
            ['sent_en', :sent],
            ['complete_en', :complete],
          )
        end

        context 'when :except is given' do
          it 'returns only filtered items' do
            expect(model.delivery_status_select_options except: :sent).
              to contain_exactly ['complete_en', :complete]
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
        expect(instance).to receive(:update_attributes!).with(status: 1)
        instance.confirmed!
      end

      context 'for custom field' do
        it 'updates field value' do
          expect(instance).to receive(:update_attributes!).with(delivery_status: 1)
          instance.delivery_sent!
        end
      end

      context 'with suffix' do
        it 'updates field value' do
          expect(instance).to receive(:update_attributes!).with(delivery_method: 2)
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
        assert_filter('"orders"."status" = 1', '') { model.with_status :confirmed }
        assert_filter('"orders"."status" = 3', '') { model.with_status 'rejected' }
        assert_filter('"orders"."status" = 5', '') { model.with_status 5 }
        assert_filter('"orders"."status" IN (1, 5)', '') { model.with_status [1, 5] }
      end

      context 'for custom field' do
        it 'filters records by field values' do
          assert_filter('"orders"."delivery_status" = 1', '') do
            model.with_delivery_status :sent
          end
          assert_filter('"orders"."delivery_status" = 4', '') do
            model.with_delivery_status 'complete'
          end
          assert_filter('"orders"."delivery_status" = 5', '') do
            model.with_delivery_status 5
          end
          assert_filter('"orders"."delivery_status" IN (1, 5)', '') do
            model.with_delivery_status [1, 5]
          end
        end
      end
    end

    describe '.#{status}' do
      it 'filters records by field values' do
        assert_filter('"orders"."status" = ?', '1') { model.confirmed }
        assert_filter('"orders"."status" = ?', '3') { model.rejected }
      end

      context 'for status with prefix' do
        it 'filters records by field value' do
          assert_filter('"orders"."delivery_status" = ?', '1') do
            model.delivery_sent
          end
          assert_filter('"orders"."delivery_status" = ?', '4') do
            model.delivery_complete
          end
        end
      end

      context 'for status with suffix' do
        it 'filters records by field value' do
          assert_filter('"orders"."delivery_method" = ?', '1') do
            model.pickup_delivery
          end
          assert_filter('"orders"."delivery_method" = ?', '3') do
            model.international_delivery
          end
        end
      end
    end

    describe '.not_#{status}' do
      it 'filters records by field values' do
        assert_filter('"orders"."status" != ?', '1') { model.not_confirmed }
      end

      context 'for status with prefix' do
        it 'filters records by field value' do
          assert_filter('"orders"."delivery_status" != ?', '1') do
            model.not_delivery_sent
          end
        end
      end

      context 'for status with suffix' do
        it 'filters records by field value' do
          assert_filter('"orders"."delivery_method" != ?', '1') do
            model.not_pickup_delivery
          end
        end
      end
    end
  end
end
