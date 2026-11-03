require 'rails_helper'

RSpec.describe(EBOL::Importer) do
  subject(:importer) { described_class.new(ActionController::Parameters.new(body).permit(described_class::PERMITTED)) }

  let(:body) { JSON.parse(file_fixture('dsdc/bol_request.json').read) }
  let(:shipment) { create(:shipment, :usd, picked_up_at: nil) }

  describe '#accessorial_codes' do
    it { expect(importer.accessorial_codes).to(eq(['LFTD', 'XYZ'])) }
  end

  describe '#bill_to_account' do
    let(:body) { super().deep_merge('billTo' => { 'account' => '42' }) }

    it { expect(importer.bill_to_account).to(eq('42')) }
  end

  describe '#include_bol?' do
    it { is_expected.not_to(be_include_bol) }
  end

  describe '#include_shipping_labels?' do
    it { is_expected.not_to(be_include_shipping_labels) }
  end

  describe '#information' do
    before { importer.shipment_attributes(shipment) }

    it { expect(importer.information.pluck(:message)).to(include(a_string_including('XYZ'))) }
  end

  describe '#shipment_attributes' do
    let(:attributes) { importer.shipment_attributes(shipment) }
    let(:item_attributes) { attributes[:items_attributes].last }
    let!(:packaging) { create(:packaging, freight_kit_type: 'pallet') }

    it { expect(attributes).to(include(bol: '5550001', customer_reference: '7770001', quote_id: '8880001', shipper_reference: '9990001')) }
    it { expect(attributes[:items_attributes].first(shipment.items.size)).to(all(include(_destroy: true))) }
    it { expect(item_attributes).to(include(declared_freight_class: 70.0, measured_l: Measured::Length.new(48, :in), measured_weight: Measured::Weight.new(900, :lb), packaging:)) }
    it { expect(attributes[:receiver_address_attributes]).to(include(id: shipment.receiver_address.id, region_iso31662: 'US-CA')) }

    context 'without handling units' do
      before { body.delete('commodities') }

      it { expect(attributes).not_to(have_key(:items_attributes)) }
    end

    context 'with a declared value in another currency' do
      before { body['shipmentTotals'] = { 'currency' => 'CAD', 'declaredValue' => 1500 } }

      it { expect(Shipment.new(attributes.slice(:value_currency, :value)).value).to(eq(Money.from_amount(1500, 'CAD'))) }
    end

    context 'with metric units' do
      before do
        body['commodities']['handlingUnits'][0].merge!('dimensionsUnit' => 'Centimeters', 'length' => 100, 'weight' => 100,
                                                       'weightUnit' => 'Kilograms')
      end

      it { expect(item_attributes).to(include(measured_l: Measured::Length.new(100, :cm), measured_weight: Measured::Weight.new(100, :kg))) }
    end

    context 'with a lowercase country and state' do
      before { body['destination'].merge!('country' => 'can', 'stateProvince' => 'on') }

      it { expect(attributes[:receiver_address_attributes]).to(include(country_alpha2: 'CA', region_iso31662: 'CA-ON')) }
    end

    context 'with an unknown country' do
      before { body['destination']['country'] = 'XYZ' }

      it { expect(attributes[:receiver_address_attributes]).not_to(include(:country_alpha2, :region_iso31662)) }
    end
  end

  describe '#test?' do
    it { is_expected.not_to(be_test) }
  end
end
