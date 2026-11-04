require 'rails_helper'

RSpec.describe(RatePolicy) do
  let(:policy) { described_class.new(build(:rate), authorizable:) }

  describe '#view_charges?' do
    subject { policy.apply(:view_charges?) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:carrier_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#view_costs?' do
    subject { policy.apply(:view_costs?) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:carrier_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end
end
