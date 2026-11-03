require 'rails_helper'

RSpec.describe(BrokerPolicy) do
  let(:policy) { described_class.new(build(:shipment), authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Customer.where(id: customer.id), type: :active_record_relation) }

    let!(:customer) { create(:customer) }

    context 'when not authorizable.broker?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(contain_exactly(customer)) }
    end
  end

  describe '#show?' do
    subject { policy.apply(:show?) }

    context 'when not authorizable.broker?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end
  end
end
