require 'rails_helper'

RSpec.describe(PaymentTransactionPolicy) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:policy) { described_class.new(PaymentTransaction, broker_carrier:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(PaymentTransaction.all, type: :active_record_relation) }

    let(:payment_transaction) { create(:payment_transaction, broker_carrier:, dsdc_unique_id: 'INV-1') }

    before do
      create(:payment_transaction, broker_carrier:)
      create(:payment_transaction, broker_carrier: create(:broker_carrier, carrier: broker_carrier.carrier), dsdc_unique_id: 'INV-2')
      create(:payment_transaction, dsdc_unique_id: 'OTHER')
      payment_transaction
    end

    it { is_expected.to(contain_exactly(payment_transaction)) }

    context 'with a user' do
      let(:policy) { described_class.new(user: create(:customer_user)) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    it { is_expected.to(be(true)) }

    context 'with a user' do
      let(:policy) { described_class.new(PaymentTransaction, user: create(:customer_user)) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'with a user' do
      let(:policy) { described_class.new(PaymentTransaction, user: create(:customer_user)) }

      it { is_expected.to(be(false)) }
    end
  end
end
