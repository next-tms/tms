require 'rails_helper'

RSpec.describe(BrokerWare) do
  describe '.accessorial_code' do
    it do
      expect(described_class.accessorial_code(build(:accessorial, code: 'DRES', transponder_code: 'residential_delivery'))).to(eq('RSDE'))
    end

    it { expect(described_class.accessorial_code(build(:accessorial, code: 'DREW', transponder_code: nil))).to(eq('DREW')) }
    it { expect(described_class.accessorial_code(nil)).to(be_nil) }
  end

  describe '.camelize' do
    it { expect(described_class.camelize(:consignee_zip)).to(eq('consigneeZip')) }
    it { expect(described_class.camelize('consignee_address2')).to(eq('consigneeAddress2')) }
    it { expect(described_class.camelize(:po_reference)).to(eq('poReference')) }
  end

  describe '.date' do
    it { expect(described_class.date('2022-1-05')).to(eq(Date.new(2022, 1, 5))) }
    it { expect(described_class.date('2021-09-01T00:00:00Z')).to(eq(Date.new(2021, 9, 1))) }
    it { expect { described_class.date('last month') }.to(raise_error(Date::Error)) }
  end

  describe '.document_list_type' do
    it { expect(described_class.document_list_type(ActiveStorage::Attachment.new(name: 'broker_bol'))).to(eq(1)) }
  end

  describe '.document_name' do
    it { expect(described_class.document_name(ActiveStorage::Attachment.new(name: 'carrier_pod'))).to(eq('POD')) }
    it { expect(described_class.document_name(ActiveStorage::Attachment.new(name: 'broker_dispatch_sheet'))).to(be_nil) }
  end

  describe '.freight_kit_type' do
    it { expect(described_class.freight_kit_type('Boxes')).to(eq(:box)) }
    it { expect(described_class.freight_kit_type('Pieces')).to(eq(:piece)) }
    it { expect(described_class.freight_kit_type('Gaylords')).to(eq(:pallet)) }
    it { expect(described_class.freight_kit_type(nil)).to(eq(:pallet)) }
  end

  describe '.shipment_status' do
    it { expect(described_class.shipment_status(Shipment.new(status: :booked_quoted))).to(eq(:booked)) }
    it { expect(described_class.shipment_status(Shipment.new(status: :pickup_scheduled))).to(eq(:dispatched)) }
    it { expect(described_class.shipment_status(Shipment.new(status: :pending_delivery_appointment))).to(eq(:in_transit)) }
  end

  describe '.status_name' do
    it { expect(described_class.status_name(Shipment.new(status: :out_for_delivery))).to(eq('OutForDelivery')) }
    it { expect(described_class.status_name(Shipment.new)).to(be_nil) }
  end

  describe '.statuses' do
    it { expect(described_class.statuses('intransit')).to(eq(%i[delivery_scheduled in_transit pending_delivery_appointment])) }
    it { expect(described_class.statuses('InTransit')).to(eq(%i[delivery_scheduled in_transit pending_delivery_appointment])) }
    it { expect(described_class.statuses('Quoted')).to(eq(%i[new_shipment quoted])) }
    it { expect(described_class.statuses('dispatch')).to(eq(%i[dispatched pickup_scheduled])) }
    it { expect(described_class.statuses('Lost')).to(be_empty) }
  end

  describe '.timestamp' do
    it { expect(described_class.timestamp(Date.new(2026, 11, 20), '2:00 PM')).to(eq('2026-11-20T14:00:00Z')) }
    it { expect(described_class.timestamp(Date.new(2026, 11, 20))).to(eq('2026-11-20T00:00:00Z')) }
    it { expect(described_class.timestamp(nil, '2:00 PM')).to(be_nil) }
  end

  describe '.transponder_code' do
    it { expect(described_class.transponder_code('LGDE')).to(eq(:liftgate_delivery)) }
    it { expect(described_class.transponder_code('rsde')).to(eq(:residential_delivery)) }
    it { expect(described_class.transponder_code('ZZZZ')).to(be_nil) }
  end
end
