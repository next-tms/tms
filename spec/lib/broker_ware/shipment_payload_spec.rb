require 'rails_helper'

RSpec.describe(BrokerWare::ShipmentPayload) do
  subject(:payload) { described_class.new(ActionController::Parameters.new(body).permit(described_class::PERMITTED), shipment:) }

  let(:body) do
    {
      bill_of_landing_note: 'Call ahead',
      consignee_address: '4011 Lana Tier',
      consignee_name: 'Fremont Receiving',
      consignee_zip: '94536',
      items: [{ class: '50', packaging: 'Pallets', pieces: 1, weight: 462 }],
      pickup_close_time: '2026-11-20T22:00:00Z',
      pickup_date: '2026-11-20T14:00:00Z',
      pickup_open_time: '2026-11-20T14:00:00Z',
      po_reference: '078219',
      shipment_status: 'Booked',
      shipper_zip: '78701'
    }
  end
  let(:receiver_location) { { city: 'Fremont', country_alpha2: 'US', region_iso31662: 'US-CA', zip_code: '94536' } }
  let(:shipment) { Shipment.new(broker_customer: create(:broker_customer)) }
  let(:shipper_location) { { city: 'Austin', country_alpha2: 'US', region_iso31662: 'US-TX', zip_code: '78701' } }

  before do
    allow(BrokerWare::Location).to(receive(:call).with('94536', nil).and_return(receiver_location))
    allow(BrokerWare::Location).to(receive(:call).with('78701', nil).and_return(shipper_location))
  end

  describe '#cancel?' do
    it { is_expected.not_to(be_cancel) }

    context 'with a canceled status' do
      before { body[:shipment_status] = 'CanceledWithCharges' }

      it { is_expected.to(be_cancel) }
    end
  end

  describe '#provided?' do
    it { is_expected.to(be_provided(:consignee_email)) }

    context 'with a persisted shipment' do
      let(:shipment) { create(:shipment) }

      it { is_expected.to(be_provided(:po_reference)) }
      it { is_expected.not_to(be_provided(:consignee_email)) }
    end
  end

  describe '#shipment_attributes' do
    subject(:shipment_attributes) { payload.shipment_attributes }

    it { is_expected.to(include(bol_notes: 'Call ahead', customer_reference: '078219', receiver_contact_email: nil)) }
    it { is_expected.to(include(pickup_hours_end_at: '10:00 PM', pickup_hours_start_at: '2:00 PM', pickup_on: Date.new(2026, 11, 20))) }
    it { is_expected.to(include(delivery_hours_end_at: nil, shipment_accessorials_attributes: [])) }
    it { expect(shipment_attributes[:items_attributes].sole).to(include(quantity: 1, weight: 462)) }
    it { expect(shipment_attributes[:receiver_address_attributes]).to(include(receiver_location)) }
    it { expect(shipment_attributes[:receiver_address_attributes]).to(include(id: nil, name: 'Fremont Receiving', street2: nil)) }
    it { expect(shipment_attributes[:receiver_address_attributes]).to(include(street: '4011 Lana Tier')) }

    context 'with a persisted shipment' do
      let(:body) { { consignee_zip: '94536', items: [{ class: '70', pieces: 2, weight: 900 }], po_reference: '4500123' } }
      let(:item) { create(:item, shipment:) }
      let(:shipment) { create(:shipment) }

      before { item }

      it { expect(shipment_attributes.keys).to(eq(%i[customer_reference items_attributes receiver_address_attributes])) }
      it { expect(shipment_attributes[:items_attributes].first).to(eq(_destroy: true, id: item.id)) }
      it { expect(shipment_attributes[:receiver_address_attributes]).to(eq(id: shipment.receiver_address_id, **receiver_location)) }
    end
  end

  describe '#status' do
    before { body[:shipment_status] = 'Canceled With_Charges' }

    it { expect(payload.status).to(eq(:canceled_with_charges)) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }

    context 'with a milestone status' do
      before do
        body[:shipment_status] = 'Delivered'
        payload.validate
      end

      it { expect(payload.errors.details[:shipment_status]).to(eq([{ error: :unsupported }])) }
    end

    context 'with an invalid time' do
      before do
        body[:pickup_open_time] = 'soon'
        payload.validate
      end

      it { expect(payload.errors.details[:pickup_open_time]).to(eq([{ error: :invalid }])) }
    end

    context 'with a persisted shipment and no zip codes' do
      let(:body) { { po_reference: '4500123' } }
      let(:shipment) { create(:shipment) }

      it { is_expected.to(be_valid) }
    end
  end
end
