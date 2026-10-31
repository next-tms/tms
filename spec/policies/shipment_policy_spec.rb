require 'rails_helper'

RSpec.describe(ShipmentPolicy) do
  let(:user) { build(:broker_user) }

  let(:shipment) { build(:shipment) }

  let(:policy) { described_class.new(shipment, user:) }

  describe '#show?' do
    subject { policy.apply(:show?) }

    context 'when not accesible_by' do
      before { allow_any_instance_of(Shipment).to(receive(:accessible_by?).with(user).and_return(false)) }

      it { is_expected.to(be(false)) }
    end

    context 'when accesible_by' do
      before { allow_any_instance_of(Shipment).to(receive(:accessible_by?).with(user).and_return(true)) }

      it { is_expected.to(be(true)) }
    end
  end
end
