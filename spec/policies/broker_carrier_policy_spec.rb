require 'rails_helper'

RSpec.describe(BrokerCarrierPolicy) do
  let(:broker_carrier) { create(:broker_carrier) }
  let!(:other_broker_carrier) { create(:broker_carrier) }
  let(:policy) { described_class.new(broker_carrier, authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(BrokerCarrier.where(id: [broker_carrier.id, other_broker_carrier.id]), type: :active_record_relation) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(contain_exactly(broker_carrier, other_broker_carrier)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: broker_carrier) }

      it { is_expected.to(contain_exactly(broker_carrier)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.carrier? for another broker carrier' do
      let(:authorizable) { build(:user, companyable: other_broker_carrier) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier? for the broker carrier' do
      let(:authorizable) { build(:user, companyable: broker_carrier) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view_markup?' do
    subject { policy.apply(:view_markup?) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.carrier? for the broker carrier' do
      let(:authorizable) { build(:user, companyable: broker_carrier) }

      it { is_expected.to(be(false)) }
    end
  end
end
