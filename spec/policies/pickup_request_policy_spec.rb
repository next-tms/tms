require 'rails_helper'

RSpec.describe(PickupRequestPolicy) do
  let(:authorizable) { create(:customer_user) }
  let(:pickup_request) { create(:pickup_request, shipments: [create(:shipment, broker_customer: authorizable.companyable)]) }
  let(:policy) { described_class.new(authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(PickupRequest.all, type: :active_record_relation) }

    before { create(:pickup_request, shipments: [create(:shipment)]) }

    it { is_expected.to(contain_exactly(pickup_request)) }

    context 'when not authorizable.is_a?(User)' do
      let(:policy) { described_class.new(authorizable: create(:broker_carrier)) }

      it { is_expected.to(be_empty) }
    end

    context "with another customer's shipment on the request" do
      before { create(:shipment, pickup_request:) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    it { is_expected.to(be(true)) }

    context 'with a broker user' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'when not authorizable.is_a?(User)' do
      let(:policy) { described_class.new(authorizable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end
  end
end
