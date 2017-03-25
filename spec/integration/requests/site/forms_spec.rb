require 'integration_helper'
require 'support/shared/statusable'

RSpec.describe Site::FormsController, type: :request do
  describe '#index' do
    subject { get controller_path }

    # For rails-4
    def document_root_element
      html_document.root
    end

    include_context 'statusable'
    before { add_translations(status: Order.statuses.list + Customer.statuses.list) }

    it 'has forms with statusable selects' do
      should be_ok
      # puts response.body

      assert_select '#new_order' do
        assert_select '[name="order[status]"]' do
          assert_select 'option', 2 do
            assert_select '[value=pending][selected=selected]', 'pending_en'
            assert_select '[value=accepted]', 'accepted_en'
          end
        end
      end

      assert_select '#order_2' do
        assert_select '[name="order[status]"]' do
          assert_select 'option', 2 do
            assert_select '[value="3"][selected=selected]', 'delivered_en'
            assert_select '[value="2"]', 'accepted_en'
          end
        end
      end

      assert_select '#new_customer' do
        assert_select '[name="customer[status]"]' do
          assert_select 'option', 2 do
            assert_select 'option[value=banned][selected=selected]', 'banned_en'
            assert_select 'option[value=verified]', 'verified_en'
          end
        end
      end
    end
  end
end
