require 'rails_helper'

RSpec.describe(TransponderService::Parser::DateTime) do
  describe '.call' do
    subject(:parsed) { described_class.call(date_time) }

    let(:date_time) do
      {
        local_date_time: '2026-10-24T09:30:00',
        location: { city: 'Fremont', country: { alpha2: 'US' }, region_abbreviation: 'CA' }
      }
    end

    context 'when an address in the same city and region has a time zone' do
      before { create(:address, city: 'Fremont', time_zone_name: 'America/Los_Angeles') }

      it { expect(parsed.time_zone.name).to(eq('America/Los_Angeles')) }
      it { expect(parsed.strftime('%H:%M')).to(eq('09:30')) }
    end

    context 'when the matching address is in another region' do
      let(:verification) { instance_double(Geo::Verification, latitude: 37.55, longitude: -121.98) }

      before do
        create(:address, city: 'Fremont', region_iso31662: 'US-TX', time_zone_name: 'America/Chicago', zip_code: '75001')
        allow(Geo).to(receive_messages(time_zone: 'America/Los_Angeles', verify: verification))
        parsed
      end

      it { expect(parsed.time_zone.name).to(eq('America/Los_Angeles')) }
      it { expect(Geo).to(have_received(:time_zone).with(latitude: 37.55, longitude: -121.98)) }
      it { expect(Geo).to(have_received(:verify).with(administrative_area: 'CA', locality: 'Fremont', region_code: 'US')) }

      context 'when the city is not found' do
        let(:verification) { nil }

        it { is_expected.to(be_nil) }
      end
    end

    context 'when the region abbreviation is not in the country' do
      let(:date_time) do
        {
          local_date_time: '2026-10-24T09:30:00',
          location: { city: 'Fremont', country: { alpha2: 'US' }, region_abbreviation: 'ON' }
        }
      end

      it { is_expected.to(be_nil) }
    end
  end
end
