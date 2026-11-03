require 'rails_helper'

RSpec.describe(TrackingEventPolicy) do
  let(:authorizable) { build(:broker_user) }
  let(:policy) { described_class.new(tracking_event, authorizable:) }
  let(:tracking_event) { build(:tracking_event, public: false) }

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'when not public and authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when public and authorizable.is_a?(BrokerCarrier)' do
      let(:policy) { described_class.new(build(:tracking_event, public: true), authorizable: build(:broker_carrier)) }

      it { is_expected.to(be(true)) }
    end
  end
end
