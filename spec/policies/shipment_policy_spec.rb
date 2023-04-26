# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ShipmentPolicy) do
  let(:user) do
    build(:user).tap do |u|
      u.companyable = create(:broker)
    end
  end

  let(:shipment) { build(:shipment) }

  let(:policy) { described_class.new(shipment, user: user) }

  describe '#show?' do
    subject { policy.apply(:show?) }

    context 'when #accesible_by is false' do
      before do
        expect_any_instance_of(Shipment).to(receive(:accessible_by?).with(user).and_return(false))
      end

      it { is_expected.to(eq(false)) }
    end

    context 'when #accesible_by is true' do
      before do
        expect_any_instance_of(Shipment).to(receive(:accessible_by?).with(user).and_return(true))
      end

      it { is_expected.to(eq(true)) }
    end
  end
end
