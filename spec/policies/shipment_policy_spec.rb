require 'rails_helper'

RSpec.describe(ShipmentPolicy) do
  let(:policy) { described_class.new(shipment, user:) }
  let(:shipment) { build(:shipment) }
  let(:user) { build(:broker_user) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Shipment.all, type: :active_record_relation) }

    let(:customer_shipment) { create(:shipment, broker_customer: user.companyable) }
    let(:user) { create(:customer_user) }

    before do
      create(:shipment)
      customer_shipment
    end

    it { is_expected.to(contain_exactly(customer_shipment)) }

    context 'with an accounts payable broker' do
      let(:customer_shipment) { create(:shipment) }
      let(:user) { create(:broker_user).tap { |user| user.add_role(:accounts_payable) } }

      it { is_expected.to(match_array(Shipment.all)) }
    end

    context 'without a user' do
      let(:policy) { described_class.new(user: nil) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#create?' do
    subject { policy.apply(:create?) }

    it { is_expected.to(be(false)) }

    context 'with a customer user' do
      let(:user) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end

    context 'without a user' do
      let(:user) { nil }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    context 'when the shipment is not accessible' do
      before { allow(shipment).to(receive(:accessible_by?).with(user).and_return(false)) }

      it { is_expected.to(be(false)) }
    end

    context 'when the shipment is accessible' do
      before { allow(shipment).to(receive(:accessible_by?).with(user).and_return(true)) }

      it { is_expected.to(be(true)) }
    end

    context 'without a user' do
      let(:user) { nil }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    before { allow(shipment).to(receive(:accessible_by?).with(user).and_return(true)) }

    it { is_expected.to(be(true)) }
  end
end
