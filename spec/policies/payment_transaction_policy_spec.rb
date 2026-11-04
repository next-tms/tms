require 'rails_helper'

RSpec.describe(PaymentTransactionPolicy) do
  let(:authorizable) { create(:carrier_user, companyable: broker_carrier.carrier) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:payment_transaction) { create(:payment_transaction, broker_carrier:) }
  let(:policy) { described_class.new(payment_transaction, authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(PaymentTransaction.all, type: :active_record_relation) }

    let!(:other_payment_transaction) { create(:payment_transaction) }

    it { is_expected.to(contain_exactly(payment_transaction)) }

    context 'with a broker user' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(be_empty) }
    end

    context 'with an accounts payable user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_payable) } }

      it { is_expected.to(contain_exactly(other_payment_transaction, payment_transaction)) }
    end

    context 'with another account of the carrier' do
      let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }
      let!(:other_account_payment_transaction) { create(:payment_transaction, broker_carrier: other_account) }

      it { is_expected.to(contain_exactly(other_account_payment_transaction, payment_transaction)) }
    end

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    it { is_expected.to(be(true)) }

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(be(false)) }
    end

    context 'with another carrier' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be(false)) }
    end

    context 'with a new record' do
      let(:payment_transaction) { PaymentTransaction.new }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'with a broker user' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(be(false)) }
    end

    context 'with a root user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:root) } }

      it { is_expected.to(be(true)) }
    end

    context 'with another carrier' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be(false)) }
    end

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user, companyable: payment_transaction.shipment.broker_customer) }

      it { is_expected.to(be(false)) }
    end

    context 'without a record' do
      let(:payment_transaction) { nil }

      it { is_expected.to(be(false)) }
    end
  end
end
