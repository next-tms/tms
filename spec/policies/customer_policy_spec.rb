require 'rails_helper'

RSpec.describe(CustomerPolicy) do
  let(:broker_customer) { create(:broker_customer) }
  let(:customer) { broker_customer.customer }
  let!(:other_customer) { create(:customer) }
  let(:policy) { described_class.new(customer, authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Customer.where(id: [customer.id, other_customer.id]), type: :active_record_relation) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(contain_exactly(customer, other_customer)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: create(:broker_carrier)) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(contain_exactly(customer)) }
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

    context 'when authorizable.customer? for another customer' do
      let(:authorizable) { build(:customer_user, companyable: create(:broker_customer, customer: other_customer)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer? for the customer' do
      let(:authorizable) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(be(true)) }
    end
  end
end
