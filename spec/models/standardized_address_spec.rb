# == Schema Information
#
# Table name: standardized_addresses
#
# @!attribute id
#   @return []
# @!attribute addresses_count
#   @return [Integer]
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute google_places_spot_cached
#   @return [String]
# @!attribute google_places_spot_updated_at
#   @return [Time]
# @!attribute key
#   @return [String]
# @!attribute latitude
#   @return [String]
# @!attribute longitude
#   @return [String]
# @!attribute open_street_map_result_cached
#   @return [String]
# @!attribute open_street_map_result_updated_at
#   @return [Time]
# @!attribute postal_code
#   @return [String]
# @!attribute region_iso31662
#   @return [String]
# @!attribute smarty_streets_result_cached
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_standardized_addresses_on_country_alpha2   (country_alpha2)
#  index_standardized_addresses_on_key              (key)
#  index_standardized_addresses_on_region_iso31662  (region_iso31662)
#
# @!attribute id
#   @return []
# @!attribute addresses_count
#   @return [Integer]
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute google_places_spot_cached
#   @return [String]
# @!attribute google_places_spot_updated_at
#   @return [Time]
# @!attribute key
#   @return [String]
# @!attribute latitude
#   @return [String]
# @!attribute longitude
#   @return [String]
# @!attribute open_street_map_result_cached
#   @return [String]
# @!attribute open_street_map_result_updated_at
#   @return [Time]
# @!attribute postal_code
#   @return [String]
# @!attribute region_iso31662
#   @return [String]
# @!attribute smarty_streets_result_cached
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_standardized_addresses_on_country_alpha2   (country_alpha2)
#  index_standardized_addresses_on_key              (key)
#  index_standardized_addresses_on_region_iso31662  (region_iso31662)
#
require 'rails_helper'

RSpec.describe(StandardizedAddress) do
  let(:record) { build(:standardized_address, country_alpha2:, region_iso31662:) }
  let(:country_alpha2) { 'US' }
  let(:region_iso31662) { 'US-CA' }

  describe '#country' do
    it { expect(record.country).to(equal(Transponder::ORM::Country.find('US'))) }
  end

  describe '#google_places_spot' do
    let(:record) { create(:standardized_address, google_places_spot_updated_at: 4.months.ago) }
    let(:service) { instance_double(Address::GooglePlacesVerifyService) }

    before do
      allow(Address::GooglePlacesVerifyService).to(receive(:new).and_return(service))
      allow(Sentry).to(receive(:capture_exception))
      allow(service).to(receive(:call).and_raise(Socket::ResolutionError, 'getaddrinfo(3)'))
    end

    it { expect(record.google_places_spot).to(be_nil) }

    it do
      record.google_places_spot
      expect(record.reload.google_places_spot_updated_at).to(be < 3.months.ago)
    end

    it do
      record.google_places_spot
      expect(Sentry).to(have_received(:capture_exception).with(an_instance_of(Socket::ResolutionError)))
    end
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
