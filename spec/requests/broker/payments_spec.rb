require 'rails_helper'

RSpec.describe('Broker::Payments') do
  before { sign_in(create(:root_broker_user)) }

  describe 'POST /broker/payment/due_payment_transactions' do
    let(:broker_carrier) { create(:broker_carrier) }

    before do
      create(:payment_transaction, broker_carrier:, due_on: Date.new(2026, 10, 1))
      create(:payment_transaction, broker_carrier:, due_on: Date.new(2026, 12, 1))
      post('/broker/payment/due_payment_transactions', params: { broker_carrier_id: broker_carrier.id, cutoff_date: '2026-11-01' })
    end

    it do
      expect(response.parsed_body).to(
        eq(
          'broker_carrier_name' => broker_carrier.broker_customer_specific_name,
          'date' => 'Nov  1 2026',
          'payment_transactions_count' => 1
        )
      )
    end
  end
end
