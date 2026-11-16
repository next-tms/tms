require 'rails_helper'

RSpec.describe('BrokerWare shipments') do
  let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
  let(:booked_shipment) { create(:shipment, :usd, **open_attributes, quote_only: false) }
  let(:broker_customer) { create(:broker_customer) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:open_attributes) do
    {
      applied_rate_id: nil,
      broker_customer:,
      delivered_at: nil,
      delivery_appointment_at: nil,
      delivery_appointment_on: nil,
      departed_origin_terminal_at: nil,
      dispatched_at: nil,
      lost_on: nil,
      out_for_delivery_at: nil,
      pending_appointment_since: nil,
      picked_up_at: nil,
      pickup_confirmation: nil,
      receiver_address: create(:address, zip_code: '94536'),
      shipper_address: create(:address, zip_code: '78701')
    }
  end
  let(:params) do
    {
      accessorials: [],
      billOfLandingNote: 'Call ahead',
      consigneeAddress: '4011 Lana Tier',
      consigneeAddress2: '',
      consigneeContact: 'Receiving',
      consigneeCountry: 'US',
      consigneeEmail: 'receiving@example.com',
      consigneeName: 'Fremont Receiving',
      consigneePhone: '(510) 555-0100',
      consigneeZip: '94536',
      equipmentType: 'van',
      items: [
        {
          class: '50',
          height: 34.0,
          isHazardous: false,
          length: 42.0,
          nmfc: '94050',
          packaging: 'Pallets',
          pieces: 1,
          productDescription: 'Chain',
          unitsDimension: 'Inches',
          unitsWeight: 'lb',
          weight: 462.0,
          width: 42.0
        }
      ],
      pickupCloseTime: '2026-11-20T22:00:00Z',
      pickupDate: '2026-11-20T14:00:00Z',
      pickupOpenTime: '2026-11-20T14:00:00Z',
      poReference: '078219',
      shipmentMode: 'LTL',
      shipperAddress: '100 Congress Ave',
      shipperContact: 'Shipping',
      shipperCountry: 'US',
      shipperEmail: 'shipping@example.com',
      shipperName: 'Austin Shipping',
      shipperNumber: '3665663',
      shipperPhone: '(512) 555-0100',
      shipperZip: '78701',
      test: false
    }
  end
  let(:shipment) { Shipment.find_by(load_id: json[:loadId]) }
  let(:verification) do
    Geo::Verification.new(
      address_lines: [],
      administrative_area: 'TX',
      authority: :commercial,
      business: true,
      dock: nil,
      fingerprint: nil,
      geocode_authority: nil,
      latitude: nil,
      locality: 'Austin',
      longitude: nil,
      place_id: nil,
      place_provider: nil,
      places: nil,
      po_box: false,
      postal_code: '78701',
      residential: false,
      verified: false
    )
  end
  let(:verifications) do
    {
      '78701' => verification,
      '94536' => verification.with(administrative_area: 'CA', locality: 'Fremont', postal_code: '94536')
    }
  end

  before do
    create(:broker_user).contact.add_role(:dispatch)
    create(:packaging, freight_kit_type: 'pallet')
    allow(Geo).to(receive(:verify)) { |postal_code:, **| verifications[postal_code] }
  end

  describe 'POST /api/v1/CancelShipment' do
    before { post('/api/v1/CancelShipment', as: :json, headers:, params: { loadId: booked_shipment.load_id.to_s }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(eq(loadId: booked_shipment.load_id)) }
    it { expect(booked_shipment.reload).to(have_attributes(booked_at: nil, canceled_at: be_present, status: 'canceled')) }

    context 'when the shipment was picked up' do
      let(:booked_shipment) { create(:shipment, broker_customer:, canceled_at: nil, picked_up_at: 1.hour.ago) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(booked_shipment.reload.canceled_at).to(be_nil) }
    end

    context 'when the shipment belongs to another customer' do
      let(:booked_shipment) { create(:shipment, picked_up_at: nil) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'POST /api/v1/createshipment' do
    before { post('/api/v1/createshipment', as: :json, headers:, params:) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.keys).to(eq([:loadId])) }
    it { expect(shipment).to(have_attributes(booked_at: be_present, broker_customer:, created_by: api_key.user, quote_only: false)) }
    it { expect(shipment).to(have_attributes(bol_notes: 'Call ahead', customer_reference: '078219', shipper_reference: '3665663')) }
    it { expect(shipment).to(have_attributes(pickup_hours_end_at: '10:00 PM', pickup_hours_start_at: '2:00 PM')) }
    it { expect(shipment.pickup_on).to(eq(Date.new(2026, 11, 20))) }
    it { expect(shipment).to(have_attributes(receiver_contact_email: 'receiving@example.com', shipper_contact_name: 'Shipping')) }
    it { expect(shipment.items.pluck(:h, :l, :quantity, :w, :weight)).to(eq([[34, 42, 1, 42, 462]])) }
    it { expect(shipment.receiver_address).to(have_attributes(city: 'Fremont', name: 'Fremont Receiving', street: '4011 Lana Tier')) }
    it { expect(shipment.shipper_address).to(have_attributes(city: 'Austin', region_iso31662: 'US-TX', zip_code: '78701')) }

    context 'with an unknown zip code' do
      let(:verifications) { {} }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json[:message]).to(be_present) }
    end

    context 'with an invalid pickup time' do
      let(:params) { super().merge(pickupOpenTime: 'soon') }

      it { is_expected.to(have_http_status(:bad_request)) }
    end
  end

  describe 'POST /api/v1/createshipment with a rate quote' do
    let(:broker_carrier) { create(:broker_carrier) }
    let(:params) { super().merge(rateQuoteId: rate.uid) }
    let(:quote) { create(:shipment, :usd, **open_attributes, booked_at: nil, quote_only: true) }
    let(:rate) { create(:rate, broker_carrier:, cost_cents: 10_000, cost_currency: 'USD', expires_at: 1.day.from_now, shipment: quote) }

    before do
      allow_any_instance_of(Rate).to(receive(:charge).and_return(Money.new(15_000, 'USD')))
      allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier)))
      post('/api/v1/createshipment', as: :json, headers:, params:)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(eq(loadId: quote.load_id)) }
    it { expect(quote.reload).to(have_attributes(applied_rate: rate, booked_at: be_present, quote_only: false)) }
    it { expect(quote.reload.customer_reference).to(eq('078219')) }

    context 'when the lane differs from the quote' do
      let(:params) { super().merge(consigneeZip: '90802') }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(quote.reload.booked_at).to(be_nil) }
    end

    context 'with an unknown rate quote' do
      let(:params) { super().merge(rateQuoteId: 'unknown') }

      it { is_expected.to(have_http_status(:bad_request)) }
    end
  end

  describe 'GET /api/v1/GetLoads' do
    let(:query) { { endDate: Date.current.iso8601, startDate: 1.day.ago.to_date.iso8601 } }

    before do
      create(:item, shipment: booked_shipment)
      create(:shipment, created_at: 1.week.ago, broker_customer:)
      create(:shipment)
      get('/api/v1/GetLoads', headers:, params: query)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.pluck(:loadId)).to(eq([booked_shipment.load_id])) }
    it { expect(json.sole).to(include(poReference: booked_shipment.customer_reference, shipmentStatus: 'Booked')) }
    it { expect(json.sole[:stops].pluck(:stopType, :zip)).to(eq([['Pickup', '78701'], ['Drop', '94536']])) }
    it { expect(json.sole[:items].first.keys).not_to(include(:billed, :cost)) }

    context 'with a matching status' do
      let(:query) { super().merge(status: 'booked') }

      it { expect(json.pluck(:loadId)).to(eq([booked_shipment.load_id])) }
    end

    context 'with another status' do
      let(:query) { super().merge(status: 'Delivered') }

      it { expect(json).to(be_empty) }
    end

    context 'with an unknown status' do
      let(:query) { super().merge(status: 'Lost') }

      it { is_expected.to(have_http_status(:bad_request)) }
    end

    context 'without dates' do
      let(:query) { {} }

      it { is_expected.to(have_http_status(:bad_request)) }
    end

    context 'with an invalid date' do
      let(:query) { super().merge(startDate: 'yesterday') }

      it { is_expected.to(have_http_status(:bad_request)) }
    end
  end

  describe 'POST /api/v1/UpdateShipment' do
    let(:update_params) { { loadId: booked_shipment.load_id, poReference: '4500123', shipmentStatus: 'Booked' } }

    before { post('/api/v1/UpdateShipment', as: :json, headers:, params: update_params) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(booked_shipment.reload.customer_reference).to(eq('4500123')) }

    context 'with new items' do
      let(:update_params) { super().merge(items: [{ class: '70', packaging: 'Pallets', pieces: 2, weight: 900 }]) }

      it { expect(booked_shipment.reload.items.pluck(:quantity, :weight)).to(eq([[2, 900]])) }
    end

    context 'with a canceled status' do
      let(:update_params) { super().merge(shipmentStatus: 'Canceled') }

      it { expect(booked_shipment.reload.canceled_at).to(be_present) }
    end

    context 'with a milestone status' do
      let(:update_params) { super().merge(shipmentStatus: 'Delivered') }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(booked_shipment.reload).to(have_attributes(customer_reference: booked_shipment.customer_reference, delivered_at: nil)) }
    end

    context 'when the shipment was picked up' do
      let(:booked_shipment) { create(:shipment, broker_customer:, picked_up_at: 1.hour.ago) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(booked_shipment.reload.customer_reference).not_to(eq('4500123')) }
    end

    context 'when the lane changes on a rated shipment' do
      let(:booked_shipment) do
        super().tap { |rated_shipment| rated_shipment.update!(applied_rate: create(:rate, shipment: rated_shipment)) }
      end
      let(:update_params) { super().merge(consigneeZip: '90802') }

      it { is_expected.to(have_http_status(:bad_request)) }
    end

    context 'without a load ID' do
      let(:update_params) { { poReference: '4500123' } }

      it { is_expected.to(have_http_status(:bad_request)) }
    end
  end
end
