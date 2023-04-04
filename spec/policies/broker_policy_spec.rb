require 'rails_helper'

RSpec.describe BrokerPolicy do
  let(:broker) { create(:broker) }

  let(:user) do
    build(:user).tap do |u|
      u.companyable = broker
    end
  end

  let(:shipment) { build(:shipment) }

  let(:policy) { described_class.new(shipment, user: user) }

  before do
    create(:intuit_account, broker: broker)
  end

  describe "#show?" do
    subject { policy.apply(:show?) }

    context "when user and record's broker is the same" do
      before { shipment.broker = broker }

      it { is_expected.to eq true }
    end

    context "when user and record's broker is not the same" do
      before { shipment.broker = create(:broker) }

      it { is_expected.to eq false }
    end
  end
end