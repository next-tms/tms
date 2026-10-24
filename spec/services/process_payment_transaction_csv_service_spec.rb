require 'rails_helper'

RSpec.describe(ProcessPaymentTransactionCsvService) do
  describe '#call' do
    subject(:service) { described_class.new(broker_carrier:, csv:, current_user: create(:broker_user)).call }

    let(:broker_carrier) { create(:broker_carrier) }
    let(:shipment) { create(:shipment, broker_carrier:, carrier_cost_cents: 10_000, carrier_cost_currency: 'USD') }
    let(:csv) { "pro,balance,date\nPRO1,25.00,2026-10-01\n" }
    let!(:payment_transaction) { create(:payment_transaction, balance_cents: 100, broker_carrier:, pro: 'PRO1', shipment:) }

    it { expect(service.status).to(eq(:success)) }
    it { expect { service }.not_to(change(PaymentTransaction, :count)) }
    it { expect { service }.to(change { payment_transaction.reload.balance_cents }.from(100).to(2500)) }
  end
end
