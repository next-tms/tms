require 'rails_helper'

RSpec.describe(Shipment::Exportable) do
  subject(:shipment) do
    create(
      :shipment,
      broker_accessorials:,
      broker_carrier:,
      broker_customer:,
      delivered_at:,
      items:,
      picked_up_at:,
      tracking_carrier:,
    )
  end

  let(:box) { create(:packaging, name: 'box') }
  let(:broker_accessorials) { [] }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:broker_customer) { create(:broker_customer) }
  let(:delivered_at) { Time.utc(2026, 10, 2, 3) }
  let(:items) { [] }
  let(:pallet) { create(:packaging, name: 'pallet') }
  let(:picked_up_at) { Time.utc(2026, 9, 29, 18) }
  let(:tracking_carrier) { nil }

  before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

  describe '.method_preloads' do
    it { expect(Shipment.method_preloads.keys).to(eq(Shipment.method_preloads.keys.sort)) }
    it { expect(ShipmentPolicy::CUSTOMER_METHODS).to(include(*Shipment.method_preloads.keys)) }
  end

  describe '#accessorial_list' do
    subject { shipment.accessorial_list }

    let(:appointment) { create(:accessorial, name: 'Appointment') }

    let(:broker_accessorials) do
      [
        create(:broker_accessorial, accessorial: create(:accessorial, name: 'Liftgate Delivery'), broker_customer:),
        create(:broker_accessorial, accessorial: appointment, broker_customer:),
        create(:broker_accessorial, accessorial: appointment, broker_customer:),
        create(:broker_accessorial, accessorial: fuel_surcharge, broker_customer:, broker_only: true),
        create(:broker_accessorial, accessorial: nil, broker_customer:)
      ]
    end

    let(:fuel_surcharge) { create(:accessorial, name: 'Fuel Surcharge') }

    it { is_expected.to(eq('appointment, liftgate delivery')) }
  end

  describe '#average_density' do
    subject { shipment.average_density }

    it { is_expected.to(be_nil) }

    context 'with dimensioned items' do
      let(:items) do
        [
          build(:item, declared_freight_class: nil, h: 12, l: 12, packaging: pallet, quantity: 1, w: 12, weight: 10),
          build(:item, declared_freight_class: nil, h: 12, l: 12, packaging: pallet, quantity: 2, w: 12, weight: 41)
        ]
      end

      it { is_expected.to(eq(15.25)) }
    end

    context 'when an item is missing dimensions' do
      let(:items) do
        [
          build(:item, declared_freight_class: nil, h: 12, l: 12, packaging: pallet, quantity: 1, w: 12, weight: 10),
          build(:item, declared_freight_class: nil, h: nil, l: nil, packaging: box, quantity: 1, w: nil, weight: 5)
        ]
      end

      it { is_expected.to(eq(Shipment::Exportable::MISSING_DIMENSIONS)) }
    end
  end

  describe '#calculated_freight_class_list' do
    subject { shipment.calculated_freight_class_list }

    let(:items) do
      [
        build(:item, declared_freight_class: nil, h: nil, l: nil, packaging: box, quantity: 1, w: nil, weight: 5),
        build(:item, declared_freight_class: 100, h: 12, l: 12, packaging: pallet, quantity: 1, w: 12, weight: 10),
        build(:item, declared_freight_class: nil, h: 12, l: 12, packaging: pallet, quantity: 1, w: 12, weight: 20)
      ]
    end

    it { is_expected.to(eq('70, 92.5, unknown')) }
  end

  describe '#carrier_name' do
    subject { shipment.carrier_name }

    it { is_expected.to(eq(broker_carrier.carrier.name)) }

    context 'when the carrier acts as a broker' do
      let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, acts_as_broker: true)) }
      let(:tracking_carrier) { create(:carrier) }

      it { is_expected.to(eq(tracking_carrier.name)) }
    end
  end

  describe '#delivery_date' do
    subject { shipment.delivery_date }

    it { is_expected.to(eq(Date.new(2026, 10, 1))) }

    context 'when not delivered' do
      let(:delivered_at) { nil }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#freight_class_list' do
    subject { shipment.freight_class_list }

    let(:items) do
      [
        build(:item, declared_freight_class: nil, h: nil, l: nil, packaging: box, quantity: 1, w: nil, weight: 5),
        build(:item, declared_freight_class: 100, h: 12, l: 12, packaging: pallet, quantity: 1, w: 12, weight: 10),
        build(:item, declared_freight_class: nil, h: 12, l: 12, packaging: pallet, quantity: 1, w: 12, weight: 20)
      ]
    end

    it { is_expected.to(eq('70, 100, unknown')) }
  end

  describe '#item_description_list' do
    subject { shipment.item_description_list }

    let(:items) do
      [
        build(:item, declared_freight_class: 70, desc: 'Candy Canes', packaging: pallet),
        build(:item, declared_freight_class: 70, desc: 'Candy Canes', packaging: pallet),
        build(:item, declared_freight_class: 70, desc: 'Gum Drops', packaging: box)
      ]
    end

    it { is_expected.to(eq('Candy Canes, Gum Drops')) }
  end

  describe '#item_summaries' do
    subject { shipment.item_summaries }

    let(:items) do
      [
        build(:item, declared_freight_class: 70, packaging: pallet),
        build(:item, declared_freight_class: 85, packaging: box)
      ]
    end

    it { is_expected.to(eq(items.map(&:summary).join("\n"))) }
  end

  describe '#loose_pieces_count' do
    subject { shipment.loose_pieces_count }

    let(:items) do
      [
        build(:item, declared_freight_class: 70, packaging: pallet, quantity: 2),
        build(:item, declared_freight_class: 70, packaging: box, quantity: 3),
        build(:item, declared_freight_class: 70, packaging: box, quantity: 4)
      ]
    end

    it { is_expected.to(eq(7)) }
  end

  describe '#palletized_count' do
    subject { shipment.palletized_count }

    let(:items) do
      [
        build(:item, declared_freight_class: 70, packaging: pallet, quantity: 2),
        build(:item, declared_freight_class: 70, packaging: box, quantity: 3)
      ]
    end

    it { is_expected.to(eq(2)) }
  end

  describe '#pickup_date' do
    subject { shipment.pickup_date }

    it { is_expected.to(eq(Date.new(2026, 9, 29))) }

    context 'when not picked up' do
      let(:picked_up_at) { nil }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#receiver_state' do
    subject { shipment.receiver_state }

    it { is_expected.to(eq(shipment.receiver_address.region.abbreviation)) }
  end

  describe '#shipper_state' do
    subject { shipment.shipper_state }

    it { is_expected.to(eq(shipment.shipper_address.region.abbreviation)) }
  end

  describe '#total_item_weight' do
    subject { shipment.total_item_weight }

    let(:items) do
      [
        build(:item, declared_freight_class: 70, packaging: pallet, weight: 400),
        build(:item, declared_freight_class: 70, packaging: box, weight: 25)
      ]
    end

    it { is_expected.to(eq(425)) }
  end
end
