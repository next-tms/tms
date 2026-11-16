require 'rails_helper'

RSpec.describe('BrokerWare rates') do
  let(:accessorial) { create(:accessorial, freight_kit_code: 'residential_delivery') }
  let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
  let(:broker_accessorial) { create(:broker_accessorial, accessorial:, broker_customer:) }
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, name: 'Fedex LTL Economy', scac: 'FXNL')) }
  let(:broker_customer) { create(:broker_customer) }
  let(:charge) { Money.new(17_314, 'USD') }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:new_rate) do
    build(
      :rate,
      broker_carrier:,
      cost_cents: 12_345,
      cost_currency: 'USD',
      freight_kit_service_type: nil,
      transit_days: 2,
      uid: rate_quote_id
    )
  end
  let(:params) do
    {
      accessorials: ['RSDE'],
      consigneeCountry: 'USA',
      consigneeZip: '94536',
      equipmentType: 'StraightVan',
      items: [
        { class: '70', isHazardous: false, nmfc: 0, packaging: 'Pallets', pieces: 1, productDescription: '', weight: 70 },
        { class: '125', isHazardous: true, packaging: 'Boxes', pieces: 5, productDescription: 'Test Desc', weight: 45 }
      ],
      miles: '0',
      shipmentMode: 'LTL',
      shipperCountry: 'USA',
      shipperZip: '78701'
    }
  end
  let(:path) { '/api/v1/rating' }
  let(:rate_quote_id) { 'e5ca6b40-634f-4560-9392-2e0267e8e6cf' }
  let(:shipment) { Shipment.find_by(created_by: api_key.user) }
  let(:verifications) do
    {
      '78701' => instance_double(Geo::Verification, administrative_area: 'TX', locality: 'Austin'),
      '94536' => instance_double(Geo::Verification, administrative_area: 'CA', locality: 'Fremont')
    }
  end

  before do
    broker_accessorial
    create(:packaging, freight_kit_type: 'box')
    create(:packaging, freight_kit_type: 'pallet')
    allow(Geo).to(receive(:verify)) { |postal_code:, **| verifications[postal_code] }
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(charge))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
    allow(Shipment::RatesService).to(receive(:call).and_return([new_rate]))
  end

  describe 'POST /api/v1/rating' do
    before { post(path, as: :json, headers:, params:) }

    it { is_expected.to(have_http_status(:ok)) }

    it do
      expect(json).to(
        eq(
          [
            {
              billed: 173.14,
              billToCode: nil,
              name: 'Fedex LTL Economy',
              scac: 'FXNL',
              serviceDescription: 'N/A',
              serviceType: 'Standard',
              transitTime: '2'
            }
          ]
        )
      )
    end

    it { expect(response.body).not_to(include('123.45', '12345')) }
    it { expect(shipment).to(have_attributes(broker_customer:, created_by: api_key.user, quote_only: true)) }

    it { expect(shipment.items.pluck(:declared_freight_class, :hazmat)).to(eq([[70.0, false], [125.0, true]])) }
    it { expect(shipment.items.pluck(:quantity, :weight)).to(eq([[1, 70], [5, 45]])) }

    it { expect(shipment.items.map { |item| item.packaging.freight_kit_type }).to(eq(['pallet', 'box'])) }
    it { expect(shipment.receiver_address).to(have_attributes(city: 'Fremont', region_iso31662: 'US-CA', zip_code: '94536')) }
    it { expect(shipment.shipment_broker_accessorials.pluck(:broker_accessorial_id)).to(eq([broker_accessorial.id])) }
    it { expect(shipment.shipper_address).to(have_attributes(city: 'Austin', region_iso31662: 'US-TX', zip_code: '78701')) }
    it { expect(Shipment::RatesService).to(have_received(:call).with(broker_carrier, shipment, declared_freight_classes: true, save: true)) }

    context 'with an accessorial the customer is not offered' do
      let(:params) { super().merge(accessorials: ['RSDE', 'LGDE']) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json[:message]).to(include('LGDE')) }
      it { expect(shipment).to(be_nil) }
    end

    context 'with an unknown zip code' do
      let(:verifications) { {} }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json[:message]).to(be_present) }
    end

    context 'without items' do
      let(:params) { super().merge(items: []) }

      it { is_expected.to(have_http_status(:bad_request)) }
    end

    context 'with an invalid item' do
      let(:params) { super().merge(items: [{ class: '70', pieces: 0, weight: 70 }]) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json[:message]).to(be_present) }
    end

    context 'when a rate is not marked up' do
      let(:charge) { Money.new(12_345, 'USD') }

      it { expect(json).to(be_empty) }
    end
  end

  describe 'POST /api/v1/RatingWithRateQuoteId' do
    let(:path) { '/api/v1/RatingWithRateQuoteId' }

    before { post(path, as: :json, headers:, params:) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.sole).to(include(accessorials: [], billed: 173.14, commodities: [], rateQuoteId: rate_quote_id)) }
    it { expect(json.sole.keys).not_to(include(:cost)) }
  end

  describe 'authentication' do
    context 'without a token' do
      let(:headers) { {} }

      before { post(path, as: :json, headers:, params:) }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(response.headers['WWW-Authenticate']).to(eq('Bearer realm="BrokerWare"')) }
    end

    context 'with the raw API key' do
      let(:headers) { { 'Authorization' => "Bearer #{api_key.token}" } }

      before { post(path, as: :json, headers:, params:) }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'when the access token expired' do
      before do
        headers
        Timecop.travel(APIKey::ACCESS_TOKEN_TTL.from_now + 1.second)
        post(path, as: :json, headers:, params:)
      end

      after { Timecop.return }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'when the API key expired after the token was issued' do
      before do
        headers
        api_key.update!(expires_at: 1.second.ago)
        post(path, as: :json, headers:, params:)
      end

      it { is_expected.to(have_http_status(:unauthorized)) }
    end
  end
end
