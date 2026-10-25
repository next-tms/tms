require 'rails_helper'

RSpec.describe(StandardizedAddress) do
  let(:record) { build(:standardized_address, country_alpha2:, region_iso31662:) }
  let(:country_alpha2) { 'US' }
  let(:region_iso31662) { 'US-CA' }

  describe '#country' do
    it { expect(record.country).to(equal(Transponder::ORM::Country.find('US'))) }
  end

  describe '#region' do
    it { expect(record.region).to(equal(Transponder::ORM::Region.find('US-CA'))) }
  end

  describe '#standardize_address' do
    let(:state_abbreviation) { 'TX' }

    before do
      allow(record).to(receive(:fetch_third_party_geolocation_services_data))
      allow(record).to(receive(:smarty_streets_result).and_return({ 'components' => { 'state_abbreviation' => state_abbreviation } }))

      record.standardize_address
    end

    it { expect(record.region_iso31662).to(eq('US-TX')) }

    context 'when the abbreviation exists only in another country' do
      let(:state_abbreviation) { 'ON' }

      it { expect(record.region_iso31662).to(eq('US-CA')) }
    end

    context 'when the record is in another country with the same abbreviation' do
      let(:country_alpha2) { 'CA' }
      let(:region_iso31662) { 'CA-ON' }
      let(:state_abbreviation) { 'BC' }

      it { expect(record.region_iso31662).to(eq('CA-BC')) }
    end
  end

  describe 'validations' do
    before { record.validate }

    context 'when the region is not within the country' do
      let(:country_alpha2) { 'CA' }

      it { expect(record.errors[:region]).to(include("isn't within Canada")) }
    end
  end
end
