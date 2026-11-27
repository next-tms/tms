require 'rails_helper'

RSpec.describe(EBOL::Exporter) do
  let(:broker_carrier) { nil }
  let(:mailing_address) { create(:address, city: 'Cheyenne', region_iso31662: 'US-WY', street: '1 Broker Way', zip_code: '82001') }
  let(:packaging) { create(:packaging, freight_kit_type: 'pallet') }
  let(:receiver_address) do
    create(
      :address,
      city: 'Fresno',
      name: 'Receiver Co',
      region_iso31662: 'US-CA',
      street: '2 Receiver Rd',
      street2: 'Dock 4',
      zip_code: '93650'
    )
  end
  let(:shipment) do
    create(
      :shipment,
      bol: 'B1',
      bol_notes: 'Call ahead',
      broker_carrier:,
      broker_customer: create(:broker_customer, always_show_quotes_based_on_calculated_classes: false, default_bol_notes: nil),
      customer_reference: '4500',
      load_id: 1001,
      pickup_on: Date.new(2026, 11, 2),
      pro: 'P1',
      quote_id: 'Q1',
      receiver_address:,
      receiver_contact_email: 'receiver@example.com',
      receiver_contact_name: 'Rita',
      receiver_contact_phone: '(559) 555-0101',
      shipper_address:,
      shipper_bol: 'SB1',
      shipper_contact_email: 'shipper@example.com',
      shipper_contact_name: 'Sam',
      shipper_contact_phone: '+1 916-555-0100',
      shipper_reference: 'SR1',
      value_cents: 150_000,
      value_currency: 'USD'
    )
  end
  let(:shipper_address) do
    create(:address, city: 'Sacramento', name: 'Shipper Co', region_iso31662: 'US-CA', street: '3 Shipper St', zip_code: '95814')
  end

  before do
    create(:setting, key: 'customer_service_email', value: 'help@broker.test')
    create(:setting, key: 'default_bol_notes', value: 'Handle with care')
    create(:setting, key: 'mailing_address', value: mailing_address)
    create(:setting, key: 'name', value: 'Broker Co')
    create(:setting, key: 'phone', value: '+17755550199')
    create(
      :item,
      declared_freight_class: 70,
      desc: 'Widgets',
      h: 40,
      hazmat: false,
      l: 48,
      nmfc: '12345',
      packaging:,
      quantity: 2,
      shipment:,
      w: 40,
      weight: 500
    )
  end

  describe '.call' do
    subject(:document) { described_class.call(Shipment.find(shipment.id)) }

    let(:bill_to) do
      {
        address1: '1 Broker Way',
        city: 'Cheyenne',
        contact: { email: 'help@broker.test', phone: '7755550199' },
        country: 'USA',
        name: 'Broker Co',
        postalCode: '82001',
        stateProvince: 'WY'
      }
    end
    let(:bol) do
      {
        function: 'Create',
        isTest: false,
        requestedPickupDate: '2026-11-02T00:00:00.000',
        requestorRole: 'Third Party',
        specialInstructions: "Handle with care\n\nCall ahead"
      }
    end
    let(:commodities) do
      {
        lineItemLayout: 'Nested',
        handlingUnits: [
          {
            count: 2,
            dimensionsUnit: 'Inches',
            height: 40,
            length: 48,
            lineItems: [
              {
                classification: '70',
                description: 'Widgets',
                hazardous: false,
                nmfc: '12345',
                packagingType: 'PAT',
                pieces: 2,
                weight: 500,
                weightUnit: 'Pounds'
              }
            ],
            type: 'PAT',
            weight: 500,
            weightUnit: 'Pounds',
            width: 40
          }
        ]
      }
    end
    let(:destination) do
      {
        address1: '2 Receiver Rd',
        address2: 'Dock 4',
        city: 'Fresno',
        contact: { email: 'receiver@example.com', name: 'Rita', phone: '5595550101' },
        country: 'USA',
        name: 'Receiver Co',
        postalCode: '93650',
        stateProvince: 'CA'
      }
    end
    let(:origin) do
      {
        address1: '3 Shipper St',
        city: 'Sacramento',
        contact: { email: 'shipper@example.com', name: 'Sam', phone: '9165550100' },
        country: 'USA',
        name: 'Shipper Co',
        postalCode: '95814',
        stateProvince: 'CA'
      }
    end
    let(:reference_numbers) do
      {
        additionalReferences: [{ name: 'Shipper Reference', value: 'SR1' }],
        bol: ['B1', 'SB1'],
        po: [{ number: '4500' }],
        pro: 'P1',
        quoteId: 'Q1',
        shipmentId: '1001'
      }
    end
    let(:shipment_totals) do
      {
        cube: 89,
        cubeDimensionsUnit: 'Feet',
        currency: 'USD',
        declaredValue: 1500,
        grossWeight: 500,
        handlingUnits: 2,
        weightUnit: 'Pounds'
      }
    end

    it { expect(document[:accessorials]).to(be_nil) }
    it { expect(document[:billTo]).to(eq(bill_to)) }
    it { expect(document[:bol]).to(eq(bol)) }
    it { expect(document[:commodities]).to(eq(commodities)) }
    it { expect(document[:destination]).to(eq(destination)) }
    it { expect(document[:origin]).to(eq(origin)) }
    it { expect(document[:payment]).to(eq(terms: 'Third Party')) }
    it { expect(document[:referenceNumbers]).to(eq(reference_numbers)) }
    it { expect(document[:shipmentTotals]).to(eq(shipment_totals)) }
    it { expect(document[:version]).to(eq('2.1.0')) }

    context 'with accessorials and a hazardous item' do
      before do
        shipment.accessorials << create(:accessorial, code: 'LGD', name: 'Liftgate Delivery', transponder_code: 'liftgate_delivery')
        shipment.accessorials << create(:accessorial, code: 'WKND', name: 'Weekend Holding')
        create(:item, declared_freight_class: 85, hazmat: true, packaging: create(:packaging, freight_kit_type: nil), shipment:)
      end

      it { expect(document[:accessorials]).to(eq(codes: ['LFTD', 'HAZ'])) }
      it { expect(document.dig(:commodities, :handlingUnits, 1, :type)).to(eq('OTH')) }
    end

    context 'with a carrier' do
      let(:broker_carrier) { create(:broker_carrier, account: 'ACCT9') }

      it { expect(document.dig(:billTo, :account)).to(eq('ACCT9')) }
      it { expect(document.dig(:billTo, :name)).to(eq('Broker Co')) }
    end

    context 'with a carrier that acts as a broker and has a billing address' do
      let(:broker_carrier) do
        broker_billing_address = create(:address, city: 'Austin', region_iso31662: 'US-TX', street: '4 Billing Blvd', zip_code: '73301')
        carrier = create(:carrier, acts_as_broker: true, broker_billing_address:)
        create(:broker_carrier, account: 'ACCT9', carrier:)
      end

      it do
        expect(document[:billTo]).to(
          include(
            address1: '4 Billing Blvd',
            city: 'Austin',
            name: broker_carrier.carrier.name,
            stateProvince: 'TX'
          )
        )
      end

      it { expect(document[:billTo]).not_to(have_key(:account)) }
    end

    context 'without a value, pickup date, or optional references' do
      before do
        shipment.update!(
          bol: nil,
          customer_reference: nil,
          pickup_on: nil,
          pro: nil,
          quote_id: nil,
          shipper_bol: nil,
          shipper_reference: nil,
          value_cents: 0
        )
      end

      it { expect(document[:bol]).not_to(have_key(:requestedPickupDate)) }
      it { expect(document[:referenceNumbers]).to(eq(shipmentId: '1001')) }
      it { expect(document[:shipmentTotals]).not_to(include(:currency, :declaredValue)) }
    end
  end

  describe '#initialize' do
    subject(:ebol) { described_class.new(Shipment.find(shipment.id)) }

    it { expect(ebol.shipment.items).to(all(satisfy { |item| item.association(:packaging).loaded? })) }
  end
end
