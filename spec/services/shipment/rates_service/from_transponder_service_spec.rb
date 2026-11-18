require 'rails_helper'

RSpec.describe(Shipment::RatesService::FromTransponderService) do
  let(:broker_carrier) { create(:broker_carrier, carrier:, encrypted_api_key: 'key', password: 'secret', username: 'user') }
  let(:carrier) { create(:carrier, :saia) }
  let(:rates) { service.call }
  let(:response) { { errors: [], rates: [transponder_rate] } }
  let(:service) { described_class.new(broker_carrier, shipment, save: false) }
  let(:shipment) { create(:shipment, broker_carrier:, pro: '12345678901', value_cents: 0) }
  let(:transponder_rate) { { 'totalCost' => { 'currency' => 'USD', 'fractional' => 12_345 }, 'transitDays' => 2 } }

  before { allow(TransponderService).to(receive(:query).and_return(response)) }

  describe '#call' do
    it { expect(rates.map(&:cost)).to(eq([Money.new(12_345, 'USD')])) }
    it { expect(rates.map(&:tracking_carrier)).to(eq([nil])) }

    context 'when the broker carrier has no API credentials' do
      let(:broker_carrier) { create(:broker_carrier, carrier:) }

      it { expect(rates).to(eq([])) }
    end

    context 'when Transponder returns errors' do
      let(:response) { { errors: [{ extensions: { code: 'API_ERROR' }, message: 'Carrier API is down' }], request: '{}', response: '{}' } }

      it { expect(rates.map(&:api_errors)).to(eq([[{ 'extensions' => { 'code' => 'API_ERROR' }, 'message' => 'Carrier API is down' }]])) }

      context 'when the carrier is not known' do
        let(:response) { { errors: [{ extensions: { code: 'CARRIER_NOT_KNOWN_ERROR' }, message: 'Carrier not known' }] } }

        it { expect(rates).to(eq([])) }
      end

      context 'when the request failed' do
        let(:response) { { errors: [{ message: 'HTTP status 500' }] } }

        it { expect(rates.map(&:api_errors)).to(eq([[{ 'message' => 'HTTP status 500' }]])) }
      end
    end

    context 'when the carrier is custom' do
      let(:carrier) { create(:carrier) }

      it { expect(rates).to(eq([])) }
    end

    context 'when the shipment has a value the carrier cannot quote' do
      let(:shipment) { create(:shipment, broker_carrier:, pro: '12345678901', value_cents: 10_000) }

      before { allow(shipment).to(receive(:broker_customer).and_return(nil)) }

      it { expect(rates.map(&:api_errors)).to(eq([[{ 'message' => 'Load declared value not supported' }]])) }
    end

    context 'when the carrier acts as a broker' do
      let(:carrier) { create(:carrier, :tql) }
      let(:transponder_rate) do
        {
          'shippingCarrier' => { 'name' => 'ESTES EXPRESS', 'scac' => 'exla' },
          'totalCost' => { 'currency' => 'USD', 'fractional' => 100 }
        }
      end

      before { service }

      it { expect(rates.map { |rate| rate.tracking_carrier.scac }).to(eq(['EXLA'])) }
      it { expect { rates }.to(change(Carrier, :count).by(1)) }
      it { expect(rates.first.tracking_carrier.name).to(eq('Estes Express')) }

      context 'when the shipping carrier exists' do
        let!(:estes) { create(:carrier, name: 'Estes', scac: 'EXLA') }

        it { expect(rates.map(&:tracking_carrier)).to(eq([estes])) }
      end
    end
  end

  describe '#carrier_finds_rate_with_declared_value?' do
    it { expect(service.__send__(:carrier_finds_rate_with_declared_value?)).to(be(false)) }

    context 'when the carrier quotes declared values' do
      let(:carrier) { create(:carrier, :tql) }

      it { expect(service.__send__(:carrier_finds_rate_with_declared_value?)).to(be(true)) }
    end
  end
end
