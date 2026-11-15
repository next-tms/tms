require 'rails_helper'

RSpec.describe(Geo, :geo) do
  let(:certified) do
    class_double(Geo::Smarty, authority: :certified, roles: %i[verification], supports?: certified_supports, verify: certified_verification)
  end
  let(:certified_supports) { true }
  let(:certified_verification) { verification.with(authority: :certified, latitude: nil, longitude: nil, place_id: nil, residential: true) }
  let(:commercial) do
    class_double(
      Geo::GoogleMaps,
      authority: :commercial,
      place:,
      resolves?: true,
      roles: %i[geocode place time_zone verification],
      supports?: commercial_supports,
      time_zone: Geo::TimeZone.new(authority: :commercial, id: 'America/Chicago'),
      verify: verification
    )
  end
  let(:commercial_supports) { true }
  let(:enabled) { [certified, commercial] }
  let(:aggregator) do
    class_double(
      Geo::GoogleMaps,
      authority: :postal_operator,
      place: aggregator_place,
      resolves?: aggregator_resolves,
      roles: %i[geocode place time_zone verification],
      supports?: true,
      time_zone: Geo::TimeZone.new(authority: :open_data, id: 'America/Denver'),
      verify: aggregator_verification
    )
  end
  let(:aggregator_place) { place.with(types: ['store']) }
  let(:aggregator_resolves) { true }
  let(:aggregator_verification) { verification.with(authority: :certified, place_id: 'aggregator-1') }
  let(:place) { Geo::Place.new(authority: :commercial, id: nil, name: nil, permanently_closed: false, types: ['restaurant']) }
  let(:verification) do
    Geo::Verification.new(
      address_lines: ['1 Main St'],
      administrative_area: 'OR',
      authority: :commercial,
      business: false,
      dock: nil,
      fingerprint: nil,
      geocode_authority: :commercial,
      latitude: 44.05,
      locality: 'Bend',
      longitude: -121.31,
      place_id: 'place-1',
      place_provider: 'google_maps',
      places: nil,
      po_box: false,
      postal_code: '97701',
      residential: false,
      verified: true
    )
  end

  before { allow(Geo::Providers).to(receive(:enabled).and_return(enabled)) }

  describe '.place' do
    subject { described_class.place('place-1', provider: 'google_maps') }

    it { is_expected.to(eq(place)) }

    context 'when the place is unknown' do
      let(:place) { Geo::Place.new(authority: :commercial, id: nil, name: nil, permanently_closed: nil, types: []) }

      it { is_expected.to(be_nil) }
    end

    context 'with an aggregator' do
      let(:enabled) { [aggregator, commercial] }

      before { described_class.place('place-1', provider: 'google_maps') }

      it { is_expected.to(eq(aggregator_place)) }
      it { expect(aggregator).to(have_received(:place).with('place-1', provider: 'google_maps')) }
      it { expect(commercial).not_to(have_received(:place)) }

      context 'when the aggregator cannot resolve the ID' do
        let(:aggregator_resolves) { false }

        it { is_expected.to(eq(place)) }
        it { expect(aggregator).not_to(have_received(:place)) }
      end
    end
  end

  describe '.time_zone' do
    subject { described_class.time_zone(latitude: 1, longitude: 2) }

    it { is_expected.to(eq('America/Chicago')) }

    context 'when no provider supports the location' do
      let(:commercial_supports) { false }

      it { is_expected.to(be_nil) }
    end

    context 'with an aggregator' do
      let(:enabled) { [aggregator, commercial] }

      it { is_expected.to(eq('America/Denver')) }
    end
  end

  describe '.verify' do
    subject(:result) { described_class.verify(postal_code: '97701', region_code: 'US') }

    before { result }

    it { is_expected.to(eq(verification.with(authority: :certified, residential: true))) }
    it { expect(certified).to(have_received(:verify).with(postal_code: '97701', region_code: 'US')) }

    context 'when the first provider is complete' do
      let(:certified_verification) { verification.with(authority: :certified, residential: true) }

      it { expect(commercial).not_to(have_received(:verify)) }
    end

    context 'when no provider answers' do
      let(:certified_verification) { nil }
      let(:verification) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when no provider verifies' do
      let(:certified_verification) { nil }
      let(:verification) { super().with(verified: false) }

      it { is_expected.to(eq(verification)) }
    end

    context 'when only a lower authority verifies' do
      let(:certified_verification) { super().with(verified: false) }

      it { is_expected.to(have_attributes(authority: :certified, residential: true, verified: false)) }
    end

    context 'when an unverified answer is complete' do
      let(:certified_verification) { verification.with(authority: :certified, verified: false) }

      it { expect(commercial).not_to(have_received(:verify)) }
    end

    context 'when a later answer has better coordinates' do
      let(:certified_verification) { super().with(geocode_authority: :certified, latitude: 1.0, longitude: 2.0) }
      let(:verification) { super().with(geocode_authority: :government) }

      it { is_expected.to(have_attributes(authority: :certified, geocode_authority: :government, latitude: 44.05, longitude: -121.31)) }
    end

    context 'when an answer has places' do
      let(:verification) { super().with(places: [place]) }

      it { expect(result.places).to(eq([place])) }
    end

    context 'when places locate the first answer' do
      let(:certified_verification) { verification.with(authority: :certified, place_id: nil, place_provider: nil, places: []) }

      it { expect(commercial).not_to(have_received(:verify)) }
    end

    context 'when a later answer has the place ID' do
      let(:certified_verification) { super().with(place_provider: nil) }

      it { is_expected.to(have_attributes(place_id: 'place-1', place_provider: 'google_maps')) }
    end

    context 'when a later answer knows the dock' do
      let(:verification) { super().with(dock: true) }

      it { is_expected.to(have_attributes(authority: :certified, dock: true)) }
    end

    context 'when a later answer has a fingerprint' do
      let(:verification) { super().with(fingerprint: '0662d1d604558fc0dc511e3dd2894215') }

      it { is_expected.to(have_attributes(authority: :certified, fingerprint: '0662d1d604558fc0dc511e3dd2894215')) }
    end

    context 'when a provider does not support the query' do
      let(:certified_supports) { false }

      it { expect(certified).not_to(have_received(:verify)) }
      it { is_expected.to(eq(verification)) }
    end

    context 'with an aggregator' do
      let(:enabled) { [aggregator, certified, commercial] }

      it { is_expected.to(eq(aggregator_verification)) }
      it { expect(certified).not_to(have_received(:verify)) }
      it { expect(commercial).not_to(have_received(:verify)) }

      context 'when the aggregator answers with less authority' do
        let(:aggregator_verification) { verification.with(place_id: 'aggregator-1', residential: nil) }

        it { is_expected.to(eq(certified_verification.with(latitude: 44.05, longitude: -121.31, place_id: 'aggregator-1'))) }
        it { expect(commercial).not_to(have_received(:verify)) }
      end
    end
  end
end
