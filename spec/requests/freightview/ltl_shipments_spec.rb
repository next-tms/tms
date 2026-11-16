require 'rails_helper'

RSpec.describe('Freightview::LTLShipments') do
  let(:api_key) { create(:api_key) }
  let(:body) { Freightview.decode_keys(JSON.parse(file_fixture('freightview/ltl_shipment_request.json').read)) }
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, name: 'Acme Freight', scac: 'ACME')) }
  let(:broker_customer) { api_key.user.companyable }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.token}", 'Content-Type' => 'application/json' } }
  let(:json) { Freightview.decode_keys(response.parsed_body) }
  let(:liftgate) { create(:accessorial, freight_kit_code: 'liftgate_delivery', name: 'Lift gate delivery') }
  let(:new_rate) { build(:rate, broker_carrier:, cost_cents: 12_345, cost_currency: 'USD', shipment:, transit_days: 3, uid: 'rate-uid') }
  let(:params) { Freightview.encode_keys(body).to_json }
  let(:path) { '/api/v2.0/shipments/ltl' }
  let(:residential) { create(:accessorial, freight_kit_code: 'residential_delivery', name: 'Residential delivery') }
  let(:shipment) { Shipment.last }

  before do
    create(:broker_user).contact.add_role(:dispatch)
    create(:broker_accessorial, accessorial: liftgate, broker_customer:)
    create(:broker_accessorial, accessorial: residential, broker_customer:)
    create(:packaging, freight_kit_type: 'pallet')
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(15_000, 'USD')))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
    allow(Shipment::RatesService).to(receive(:call) { [new_rate] })
  end

  describe 'POST /api/v2.0/shipments/ltl' do
    context 'without returnQuotes' do
      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:created)) }
      it { expect(json).to(include(bol: { bol_number: '1001', status: 'not-requested' }, status: 'pending')) }
      it { expect(json[:shipment_id]).to(eq(shipment.load_id.to_s)) }
      it { expect(json).not_to(have_key(:quotes)) }
      it { expect(Shipment::RatesService).not_to(have_received(:call)) }
      it { expect(shipment).to(have_attributes(broker_customer:, created_by: api_key.user, pickup_on: Date.new(2026, 11, 17))) }
      it { expect(shipment).to(be_quote_only) }
      it { expect(shipment.broker_accessorials.map(&:accessorial)).to(contain_exactly(liftgate, residential)) }
      it { expect(shipment.items.sole).to(have_attributes(declared_freight_class: 70.0, desc: 'Widgets', nmfc: '12345-2')) }
      it { expect(shipment.items.sole).to(have_attributes(quantity: 2, weight: 500)) }
      it { expect(shipment.receiver_address).to(have_attributes(city: 'Fremont', name: 'Acme Receiving', region_iso31662: 'US-CA')) }
      it { expect(shipment).to(have_attributes(delivery_hours_end_at: '4:30 PM', pickup_hours_start_at: '8:00 AM')) }
      it { expect(shipment.receiver_contact_email).to(eq('receiving@example.com')) }
    end

    context 'with returnQuotes' do
      let(:path) { '/api/v2.0/shipments/ltl?returnQuotes=true' }
      let(:quote) { json[:quotes].sole }

      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:created)) }
      it { expect(quote).to(include(amount: 150.0, currency: 'usd')) }
      it { expect(quote).to(include(asset_carrier_code: 'ACME', asset_carrier_name: 'Acme Freight')) }
      it { expect(quote).to(include(quote_id: 'rate-uid', status: 'active', transit_days_max: 3, transit_days_min: 3)) }
      it { expect(quote.to_s).not_to(include('123.45')) }
    end

    context 'with an accessorial the customer is not offered' do
      let(:body) { super().deep_merge(destination: { accessorials: { notify: true } }) }

      before do
        create(:accessorial, freight_kit_code: 'notify_before_delivery', name: 'Notify before delivery')
        post(path, headers:, params:)
      end

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(include(name: 'ValidationError', request_id: be_present)) }
      it { expect(json[:errors]).to(match([{ message: be_present, property_name: 'accessorials' }])) }
      it { expect(Shipment.count).to(eq(0)) }
    end

    context 'with an accessorial Freightview supports but TMS does not' do
      let(:body) { super().deep_merge(destination: { accessorials: { sort_and_segregate: true } }) }

      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json[:errors].pluck(:property_name)).to(eq(['destination.accessorials.sortAndSegregate'])) }
    end

    context 'without pickupDate' do
      let(:body) { super().except(:pickup_date) }

      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json[:errors].pluck(:property_name)).to(eq(['pickupDate'])) }
    end

    context 'with an invalid opensAt' do
      let(:body) { super().deep_merge(origin: { opens_at: 'noon' }) }

      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(Shipment.count).to(eq(0)) }
    end

    context 'when the API key belongs to a broker user' do
      let(:api_key) { create(:api_key, user: create(:broker_user)) }
      let(:broker_customer) { create(:broker_customer) }

      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:forbidden)) }
      it { expect(json[:name]).to(eq('ForbiddenError')) }
    end

    context 'without an API key' do
      let(:headers) { { 'Content-Type' => 'application/json' } }

      before { post(path, headers:, params:) }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json[:name]).to(eq('UnauthorizedError')) }
    end
  end
end
