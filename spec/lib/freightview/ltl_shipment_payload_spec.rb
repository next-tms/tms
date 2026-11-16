require 'rails_helper'

RSpec.describe(Freightview::LTLShipmentPayload) do
  subject(:payload) { described_class.new(body) }

  let(:body) { Freightview.decode_keys(JSON.parse(file_fixture('freightview/ltl_shipment_request.json').read)) }

  before { create(:packaging, freight_kit_type: 'pallet') }

  describe '#accessorial_codes' do
    it { expect(payload.accessorial_codes).to(eq(%i[liftgate_delivery residential_delivery])) }

    context 'with origin accessorials and a limited access origin' do
      let(:body) { super().deep_merge(origin: { accessorials: { inside: true }, ship_type: 'limited access' }) }

      it { expect(payload.accessorial_codes).to(include(:inside_pickup, :limited_access_pickup)) }
    end
  end

  describe '#shipment_attributes' do
    let(:attributes) { payload.shipment_attributes }
    let(:shipper_address) { { city: 'Austin', country_alpha2: 'US', name: 'Acme Shipping', region_iso31662: 'US-TX', zip_code: '78701' } }

    it { expect(attributes).to(include(bol: '1001', pickup_hours_end_at: '5:00 PM', pickup_on: Date.new(2026, 11, 17))) }
    it { expect(attributes).to(include(receiver_contact_name: 'Riley Receiver', receiver_contact_phone: '5105550100')) }
    it { expect(attributes).not_to(have_key(:shipper_contact_email)) }
    it { expect(attributes[:shipper_address_attributes]).to(eq(shipper_address)) }
    it { expect(attributes[:items_attributes].sole).to(include(desc: 'Widgets', h: 48, hazmat: false, nmfc: '12345-2')) }
    it { expect(attributes[:items_attributes].sole).to(include(packaging: Packaging.find_by(freight_kit_type: 'pallet'))) }

    context 'with a phone extension' do
      let(:body) { super().deep_merge(destination: { contact_phone_ext: '12' }) }

      it { expect(attributes[:receiver_contact_phone]).to(eq('5105550100 x12')) }
    end

    context 'with an unknown packaging type' do
      let(:body) { super().merge(items: [{ quantity: 1, type: 'keg', weight: 100 }]) }

      it { expect(attributes[:items_attributes].sole).to(include(desc: 'Freight', packaging: nil)) }
    end

    context 'without a state' do
      let(:body) { super().deep_merge(origin: { state: '' }) }

      it { expect(attributes[:shipper_address_attributes]).not_to(have_key(:region_iso31662)) }
    end

    context 'without an origin' do
      let(:body) { super().except(:origin) }

      it { expect { attributes }.to(raise_error(ActionController::ParameterMissing)) }
    end

    context 'with an invalid opensAt' do
      let(:body) { super().deep_merge(origin: { opens_at: 'noon' }) }

      it { expect { attributes }.to(raise_error(ArgumentError)) }
    end
  end

  describe '#unsupported_accessorials' do
    it { expect(payload.unsupported_accessorials).to(be_empty) }

    context 'with sortAndSegregate' do
      let(:body) { super().deep_merge(destination: { accessorials: { sort_and_segregate: true } }) }

      it { expect(payload.unsupported_accessorials).to(eq([%i[destination accessorials sort_and_segregate]])) }
    end
  end
end
