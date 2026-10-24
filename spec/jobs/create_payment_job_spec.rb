require 'rails_helper'

RSpec.describe(CreatePaymentJob) do
  describe '#perform' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:due_on) { Date.new(2026, 11, 1) }
    let!(:payment_transaction) { create(:payment_transaction, broker_carrier:, due_on:) }

    before { described_class.perform_now(broker_carrier:, payment_transaction_ids: [ payment_transaction.id ]) }

    it { expect(Payment.last).to(have_attributes(broker_carrier:, due_on:)) }
    it { expect(payment_transaction.reload.payment).to(eq(Payment.last)) }
  end
end
