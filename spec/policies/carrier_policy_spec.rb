require 'rails_helper'

RSpec.describe(CarrierPolicy) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:carrier) { broker_carrier.carrier }
  let!(:other_carrier) { create(:carrier) }
  let(:policy) { described_class.new(carrier, authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Carrier.where(id: [carrier.id, other_carrier.id]), type: :active_record_relation) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(contain_exactly(carrier, other_carrier)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: broker_carrier.carrier) }

      it { is_expected.to(contain_exactly(carrier)) }
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

    context 'when authorizable.carrier? for another carrier' do
      let(:authorizable) { build(:user, companyable: other_carrier) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier? for the carrier' do
      let(:authorizable) { build(:user, companyable: broker_carrier.carrier) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end
end
