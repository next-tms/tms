require 'rails_helper'

RSpec.describe(BrokerCustomerPolicy) do
  let(:broker_customer) { create(:broker_customer) }
  let!(:other_broker_customer) { create(:broker_customer) }
  let(:policy) { described_class.new(broker_customer, authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(BrokerCustomer.where(id: [broker_customer.id, other_broker_customer.id]), type: :active_record_relation) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(contain_exactly(broker_customer, other_broker_customer)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: create(:broker_carrier)) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(contain_exactly(broker_customer)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: create(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer? for another broker customer' do
      let(:authorizable) { build(:customer_user, companyable: other_broker_customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer? for the broker customer' do
      let(:authorizable) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#view_markup?' do
    subject { policy.apply(:view_markup?) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.customer? for the broker customer' do
      let(:authorizable) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(be(false)) }
    end
  end
end
