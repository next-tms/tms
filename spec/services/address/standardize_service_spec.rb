require 'rails_helper'

RSpec.describe(Address::StandardizeService) do
  describe '#call' do
    subject(:call) { described_class.new(address:).call }

    let(:address) do
      build(
        :address,
        city: 'Fremont',
        latitude: nil,
        longitude: nil,
        street: '4011 Lana Tier',
        street2: 'Suite 1',
        time_zone_name: nil,
        zip_code: '94536'
      )
    end
    let(:place) { Geo::Place.new(authority: :commercial, id: nil, name: nil, permanently_closed: false, types: ['restaurant']) }
    let(:time_zone) { 'America/Los_Angeles' }
    let(:verification) do
      Geo::Verification.new(
        address_lines: ['4011 Lana Tier Ste 1'],
        administrative_area: 'CA',
        authority: :commercial,
        business: true,
        dock: true,
        fingerprint: '0662d1d604558fc0dc511e3dd2894215',
        geocode_authority: :commercial,
        latitude: 37.55,
        locality: 'Fremont',
        longitude: -121.98,
        place_id: 'place-1',
        place_provider: 'google_maps',
        places: nil,
        po_box: false,
        postal_code: '94536-1234',
        residential: false,
        verified: true
      )
    end

    before do
      allow(Geo).to(receive_messages(place:, time_zone:, verify: verification))
      call
    end

    it do
      expect(Geo).to(
        have_received(:verify)
          .with(
            address_lines: ['4011 Lana Tier', 'Suite 1'],
            administrative_area: 'CA',
            locality: 'Fremont',
            postal_code: '94536',
            region_code: 'US'
          )
      )
    end

    it do
      expect(address).to(
        have_attributes(
          business: true,
          city: 'Fremont',
          dock: true,
          fingerprint: '0662d1d604558fc0dc511e3dd2894215',
          permanently_closed: false,
          place_id: 'place-1',
          po_box: false,
          region_iso31662: 'US-CA',
          residential: false,
          street: '4011 Lana Tier Ste 1',
          street2: nil,
          time_zone_name: 'America/Los_Angeles',
          zip_code: '94536-1234'
        )
      )
    end

    it { expect(address.latitude.to_f).to(eq(37.55)) }
    it { expect(address.longitude.to_f).to(eq(-121.98)) }
    it { expect(address[:types]).to(eq(['restaurant'])) }
    it { expect(Geo).to(have_received(:place).with('place-1', provider: 'google_maps')) }
    it { expect(Geo).to(have_received(:time_zone).with(latitude: 37.55, longitude: -121.98)) }

    context 'when the address is not verified' do
      let(:verification) { super().with(verified: false) }

      it { expect(address).to(have_attributes(place_id: 'place-1', street: '4011 Lana Tier Ste 1', street2: nil, zip_code: '94536-1234')) }
      it { expect(Geo).to(have_received(:place).with('place-1', provider: 'google_maps')) }
    end

    context 'when the place lookup fails' do
      let(:place) { nil }

      it { expect(address).to(have_attributes(permanently_closed: nil, place_id: 'place-1')) }
      it { expect(address[:types]).to(eq([])) }
    end

    context 'when the provider fails' do
      let(:verification) { nil }

      it { expect(address).to(have_attributes(place_id: nil, residential: nil, street: '4011 Lana Tier')) }
    end

    context 'when the answer has no street lines' do
      let(:verification) { super().with(address_lines: []) }

      it { expect(address).to(have_attributes(street: '4011 Lana Tier', street2: 'Suite 1')) }
    end

    context 'when a saved address moves' do
      let(:address) do
        create(:address, latitude: 1, longitude: 2, residential: true, time_zone_name: 'America/New_York', zip_code: '10001')
          .tap { it.assign_attributes(city: 'Fremont', street: '4011 Lana Tier', street2: 'Suite 1', zip_code: '94536') }
      end
      let(:verification) { nil }

      it { expect(address).to(have_attributes(latitude: nil, longitude: nil, residential: nil, time_zone_name: nil)) }

      context 'when the street is cleared' do
        let(:address) do
          create(:address, latitude: 1, longitude: 2, residential: true, time_zone_name: 'America/New_York').tap { it.street = nil }
        end

        it { expect(address).to(have_attributes(latitude: nil, longitude: nil, residential: nil, time_zone_name: nil)) }
        it { expect(Geo).not_to(have_received(:verify).with(hash_including(address_lines: []))) }
      end

      context 'when only the name changes' do
        let(:address) do
          create(:address, latitude: 1, longitude: 2, residential: true, time_zone_name: 'America/New_York').tap { it.name = 'Acme' }
        end

        it { expect(address).to(have_attributes(latitude: 1, longitude: 2, residential: true, time_zone_name: 'America/New_York')) }
      end
    end

    context 'when a saved address is renamed' do
      let(:address) do
        create(:address).tap do |address|
          address.update_columns(city: 'Fremont', residential: false, zip_code: '94536') # rubocop:disable Rails/SkipsModelValidations
          address.name = 'Acme'
        end
      end
      let(:verification) { super().with(locality: 'Newark', places: [place.with(name: 'Acme')], postal_code: '07102', residential: true) }

      it { expect(address).to(have_attributes(city: 'Fremont', residential: false, zip_code: '94536')) }
      it { expect(address[:types]).to(eq(['restaurant'])) }
    end

    context 'when the region abbreviation is unknown' do
      let(:verification) { super().with(administrative_area: 'ZZ') }

      it { expect(address.region_iso31662).to(eq('US-CA')) }
    end

    context 'when the time zone lookup fails' do
      let(:time_zone) { nil }

      it { expect(address.time_zone_name).to(be_nil) }
    end

    context 'with places at the address' do
      let(:address) { super().tap { |address| address.name = 'Taco Spot!' } }
      let(:office) { place.with(id: 'office-1', name: 'Office', types: ['government']) }
      let(:places) { [office, place.with(id: 'taco-1', name: 'TACO SPOT', permanently_closed: true)] }
      let(:verification) { super().with(places:) }

      it { expect(address).to(have_attributes(permanently_closed: true, types: ['restaurant'])) }
      it { expect(Geo).not_to(have_received(:place)) }

      context 'when no place has the name' do
        let(:places) { [office] }

        it { expect(address).to(have_attributes(permanently_closed: nil, types: [])) }
      end

      context 'when the address has no name' do
        let(:address) { super().tap { |address| address.name = nil } }
        let(:places) { [office.with(name: nil)] }

        it { expect(address[:types]).to(eq([])) }
      end
    end

    context 'without a place ID' do
      let(:verification) { super().with(place_id: nil) }

      it { expect(Geo).not_to(have_received(:place)) }
    end
  end
end
