require 'rails_helper'

RSpec.describe(ShipmentBrokerAccessorial) do
  subject(:shipment_broker_accessorial) { create(:shipment_broker_accessorial, broker_accessorial:, cost:) }

  let(:broker_accessorial) { create(:broker_accessorial, upcharge_cents: 250, upcharge_currency: currency, upcharge_percent: 10) }
  let(:cost) { nil }
  let(:currency) { Faker::Currency.code }

  describe 'relationships' do
    it { is_expected.to(belong_to(:broker_accessorial)) }
    it { is_expected.to(belong_to(:shipment)) }
  end

  describe 'validations' do
    subject(:shipment_broker_accessorial) { described_class.new }

    it { is_expected.not_to(be_valid) }
    it { expect { shipment_broker_accessorial.valid? }.not_to(raise_error) }
  end

  describe '#charge' do
    subject { shipment_broker_accessorial.charge }

    it { is_expected.to(eq(Money.new(250, currency))) }

    context 'with a cost' do
      let(:cost) { Money.new(1_000, currency) }

      it { is_expected.to(eq(Money.new(1_350, currency))) }
    end
  end

  describe '#cost' do
    subject { shipment_broker_accessorial.cost }

    it { is_expected.to(eq(Money.new(0, currency))) }

    context 'with a cost' do
      let(:cost) { Money.new(1_000, currency) }

      it { is_expected.to(eq(cost)) }
    end
  end
end
