require 'rails_helper'

RSpec.describe(TransponderService::Parser::DateTime) do
  describe '.call' do
    let(:date_time) do
      {
        local_date_time: '2026-10-24T09:30:00',
        location: { city: 'Fremont', country: { alpha2: 'US' }, region_abbreviation: 'CA' }
      }
    end

    context 'when a standardized address in the same city and region has a time zone' do
      before { create(:standardized_address, city: 'Fremont', time_zone_name: 'America/Los_Angeles') }

      it { expect(described_class.call(date_time).time_zone.name).to(eq('America/Los_Angeles')) }
      it { expect(described_class.call(date_time).strftime('%H:%M')).to(eq('09:30')) }
    end

    context 'when the matching standardized address is in another region' do
      let(:client) { instance_double(GooglePlaces::Client, spots_by_query: []) }

      before do
        create(:standardized_address, city: 'Fremont', region_iso31662: 'US-TX', time_zone_name: 'America/Chicago')
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('GOOGLE_API_KEY').and_return('mock_api_key'))
        allow(GooglePlaces::Client).to(receive(:new).with('mock_api_key').and_return(client))
      end

      it { expect(described_class.call(date_time)).to(be_nil) }

      it do
        described_class.call(date_time)

        expect(client).to(have_received(:spots_by_query).with('Fremont, CA, US'))
      end
    end

    context 'when the region abbreviation is not in the country' do
      let(:date_time) do
        {
          local_date_time: '2026-10-24T09:30:00',
          location: { city: 'Fremont', country: { alpha2: 'US' }, region_abbreviation: 'ON' }
        }
      end

      it { expect(described_class.call(date_time)).to(be_nil) }
    end
  end
end
