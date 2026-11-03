require 'rails_helper'

RSpec.describe(DispatchAndSalesRepPolicy) do
  let(:authorizable) { create(:broker_user) }
  let(:policy) { described_class.new(shipment, authorizable:) }
  let(:shipment) { create(:shipment, broker_carrier: create(:broker_carrier)) }

  describe '#accounts_and_claims_show?' do
    subject { policy.apply(:accounts_and_claims_show?) }

    it { is_expected.to(be(false)) }

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when the user is the dispatcher' do
      before { shipment.update!(dispatcher: authorizable) }

      it { is_expected.to(be(true)) }
    end

    context 'with the claims role' do
      before { authorizable.add_role(:claims) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#accounts_show?' do
    subject { policy.apply(:accounts_show?) }

    it { is_expected.to(be(false)) }

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when the user is a sales rep for the broker customer' do
      before { BrokerCustomerSalesRep.create!(broker_customer: shipment.broker_customer, commission_percent: 5, user: authorizable) }

      it { is_expected.to(be(true)) }
    end

    context 'with the accounts_payable role' do
      before { authorizable.add_role(:accounts_payable) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#show?' do
    subject { policy.apply(:show?) }

    it { is_expected.to(be(false)) }

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when the user is a sales rep for the broker customer' do
      before { BrokerCustomerSalesRep.create!(broker_customer: shipment.broker_customer, commission_percent: 5, user: authorizable) }

      it { is_expected.to(be(true)) }
    end

    context 'with the dispatch role' do
      before { authorizable.add_role(:dispatch) }

      it { is_expected.to(be(true)) }
    end
  end
end
