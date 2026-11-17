require 'rails_helper'

RSpec.describe(TrackingEventPolicy) do
  let(:authorizable) { build(:broker_user) }
  let(:carrier) { create(:carrier) }
  let(:policy) { described_class.new(tracking_event, authorizable:) }
  let(:public) { false }
  let(:tracking_carrier) { nil }
  let(:tracking_event) { build(:tracking_event, public:, shipment: build(:shipment, tracking_carrier:)) }

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'when not public and authorizable.carrier?' do
      let(:authorizable) { build(:carrier_user, companyable: carrier) }

      it { is_expected.to(be(false)) }

      context 'when the carrier is the tracking carrier' do
        let(:tracking_carrier) { carrier }

        it { is_expected.to(be(true)) }
      end

      context 'when another carrier is the tracking carrier' do
        let(:tracking_carrier) { create(:carrier) }

        it { is_expected.to(be(false)) }
      end
    end

    context 'when not public and authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when public and authorizable.carrier?' do
      let(:authorizable) { build(:carrier_user) }
      let(:public) { true }

      it { is_expected.to(be(true)) }
    end
  end
end
