require 'rails_helper'

RSpec.describe(Shipment::QuotableRatesService) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:broker_carriers) { BrokerCarrier.where(id: [broker_carrier, other_broker_carrier]) }
  let(:charge) { Money.new(15_000, 'USD') }
  let(:cheap_rate) { build(:rate, broker_carrier:, cost_cents: 9_000, cost_currency: 'USD') }
  let(:other_broker_carrier) { create(:broker_carrier) }
  let(:rate) { build(:rate, broker_carrier:, cost_cents: 12_345, cost_currency: 'USD') }
  let(:shipment) { create(:shipment) }
  let(:user_type) { :customer }

  before do
    allow_any_instance_of(Rate).to(receive(:charge).and_return(charge))
    allow(shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(broker_carriers))
    allow(Shipment::RatesService).to(receive(:call).and_return([]))
    allow(Shipment::RatesService).to(receive(:call).with(broker_carrier, any_args).and_return([rate, cheap_rate]))
  end

  describe '.call' do
    subject(:rates) { described_class.call(shipment, user_type:) }

    it { is_expected.to(eq([cheap_rate, rate])) }

    context 'with the rates request' do
      before { rates }

      it { expect(Shipment::RatesService).to(have_received(:call).with(broker_carrier, shipment, declared_freight_classes: false, save: true)) }
      it { expect(shipment).to(have_received(:valid_broker_carriers_for_quotation).with(:customer)) }
    end

    context 'with a broker carrier' do
      subject(:rates) { described_class.call(shipment, broker_carrier_id: other_broker_carrier.id, user_type:) }

      it { is_expected.to(be_empty) }
    end

    context 'with a saved unexpired rate' do
      subject(:rates) { described_class.call(shipment, declared_freight_classes: true, user_type:) }

      let!(:saved_rate) do
        create(:rate, broker_carrier:, cost_cents: 10_000, declared_freight_classes: true, expires_at: 1.day.from_now, shipment:)
      end

      before { rates }

      it { is_expected.to(eq([saved_rate])) }
      it { expect(Shipment::RatesService).not_to(have_received(:call).with(broker_carrier, any_args)) }
    end
  end

  describe '.quotable?' do
    it { expect(described_class.quotable?(rate, user_type:)).to(be(true)) }
    it { expect(described_class.quotable?(build(:rate, cost_cents: 0), user_type:)).to(be(false)) }
    it { expect(described_class.quotable?(build(:rate, cost_cents: 20_000, cost_currency: 'USD'), user_type:)).to(be(false)) }
    it { expect(described_class.quotable?(build(:rate, cost_cents: 20_000, cost_currency: 'USD'), user_type: :broker)).to(be(true)) }

    context 'without a charge' do
      let(:charge) { nil }

      it { expect(described_class.quotable?(rate, user_type:)).to(be(false)) }
    end
  end
end
