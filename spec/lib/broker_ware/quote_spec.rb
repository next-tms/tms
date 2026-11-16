require 'rails_helper'

RSpec.describe(BrokerWare::Quote) do
  subject(:quote) { described_class.new(ActionController::Parameters.new(body).permit(described_class::PERMITTED), broker_customer:) }

  let(:accessorial) { create(:accessorial, code: 'DRES', freight_kit_code: 'residential_delivery') }
  let(:body) do
    {
      accessorials: ['rsde', 'RSDE', ''],
      consignee_country: 'USA',
      consignee_zip: '94536',
      items: [
        { class: '70', height: 0, is_hazardous: 'true', nmfc: 0, packaging: 'Boxes', pieces: 2, product_description: '', weight: 70.2 },
        { class: '', height: 48, is_hazardous: false, nmfc: '1566', packaging: 'Loose', pieces: 1, product_description: 'Desk', weight: 45 }
      ],
      shipper_country: 'USA',
      shipper_zip: '78701'
    }
  end
  let(:box) { create(:packaging, freight_kit_type: 'box') }
  let(:broker_accessorial) { BrokerAccessorial.find_by(accessorial:) }
  let(:broker_customer) { create(:broker_customer) }
  let(:pallet) { create(:packaging, freight_kit_type: 'pallet') }
  let(:receiver_location) { { city: 'Fremont', country_alpha2: 'US', region_iso31662: 'US-CA', zip_code: '94536' } }
  let(:shipper_location) { { city: 'Austin', country_alpha2: 'US', region_iso31662: 'US-TX', zip_code: '78701' } }

  before do
    accessorial
    box
    pallet
    allow(BrokerWare::Location).to(receive(:call).with('94536', 'USA').and_return(receiver_location))
    allow(BrokerWare::Location).to(receive(:call).with('78701', 'USA').and_return(shipper_location))
  end

  describe '#accessorial_codes' do
    it { expect(quote.accessorial_codes).to(eq(['RSDE'])) }
  end

  describe '#declared_freight_classes?' do
    it { is_expected.not_to(be_declared_freight_classes) }

    context 'when every item has a class' do
      before { body[:items].second[:class] = '125' }

      it { is_expected.to(be_declared_freight_classes) }
    end
  end

  describe '#items' do
    it { expect(quote.items.size).to(eq(2)) }
  end

  describe '#provided?' do
    it { is_expected.to(be_provided(:items)) }
  end

  describe '#read_attribute_for_validation' do
    it { expect(quote.read_attribute_for_validation(:accessorials)).to(eq(['rsde', 'RSDE', ''])) }
    it { expect(quote.read_attribute_for_validation(:shipper_zip)).to(eq('78701')) }
  end

  describe '#receiver_location' do
    it { expect(quote.receiver_location).to(eq(receiver_location)) }
  end

  describe '#shipment_attributes' do
    it { expect(quote.shipment_attributes).to(include(receiver_address_attributes: receiver_location)) }
    it { expect(quote.shipment_attributes).to(include(shipper_address_attributes: shipper_location)) }

    it do
      expect(quote.shipment_attributes[:shipment_broker_accessorials_attributes]).to(eq([{ broker_accessorial_id: broker_accessorial.id }]))
    end

    it do
      expect(quote.shipment_attributes[:items_attributes]).to(
        eq(
          [
            {
              declared_freight_class: 70.0,
              desc: 'Freight',
              h: nil,
              hazmat: true,
              l: nil,
              nmfc: nil,
              packaging: box,
              quantity: 2,
              w: nil,
              weight: 71
            },
            {
              declared_freight_class: nil,
              desc: 'Desk',
              h: 48,
              hazmat: false,
              l: nil,
              nmfc: '1566',
              packaging: pallet,
              quantity: 1,
              w: nil,
              weight: 45
            }
          ]
        )
      )
    end

    context 'with metric units' do
      before { body[:items] = [{ height: 100, pieces: 1, units_dimension: 'cm', units_weight: 'kg', weight: 10 }] }

      it { expect(quote.shipment_attributes[:items_attributes].sole).to(include(h: 39, weight: 23)) }
    end
  end

  describe '#shipper_location' do
    it { expect(quote.shipper_location).to(eq(shipper_location)) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }

    context 'with an accessorial the customer is not offered' do
      before do
        body[:accessorials] = ['RSDE', 'LGDE']
        quote.validate
      end

      it { expect(quote.errors.details[:accessorials]).to(eq([{ codes: 'LGDE', error: :unserviceable }])) }
    end

    context 'with a TMS accessorial code' do
      before { body[:accessorials] = ['DRES'] }

      it { is_expected.to(be_valid) }
    end

    context 'without items' do
      before { body[:items] = [] }

      it { is_expected.not_to(be_valid) }
    end

    context 'with an unknown zip code' do
      let(:shipper_location) { nil }

      before { quote.validate }

      it { expect(quote.errors.details[:shipper_zip]).to(eq([{ error: :unknown }])) }
    end
  end
end
