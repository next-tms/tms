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
# @!attribute country_id
#   @return []
# @!attribute region_id
#   @return []
#
# Indexes
#
#  index_standardized_addresses_on_country_id  (country_id)
#  index_standardized_addresses_on_key         (key)
#  index_standardized_addresses_on_region_id   (region_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (region_id => regions.id)
#
FactoryBot.define do
  factory :standardized_address do
    google_places_spot_updated_at { '2023-06-09 23:54:53' }
    open_street_map_result_updated_at { '2023-06-09 23:54:53' }
    smarty_streets_result_updated_at { '2023-06-09 23:54:53' }
    addresses_count { 1 }
    country { create(:country) }
    region { create(:region) }
    city { 'MyString' }
    key { 'MyString' }
    latitude { 'MyString' }
    longitude { 'MyString' }
    postal_code { 'MyString' }
    street { 'MyString' }
    street2 { 'MyString' }
    google_places_spot_cached { 'MyText' }
    open_street_map_result_cached { 'MyText' }
    smarty_streets_result_cached { 'MyText' }
    time_zone_name { 'America/Los_Angeles' }

    after(:build) do |s|
      s.class.skip_callback(:validation, :before, :standardize_address)
    end

    after(:build) do |s|
      s.class.skip_callback(:validation, :before, :set_coordinates)
    end

    after(:build) do |s|
      s.class.skip_callback(:validation, :before, :set_time_zone_name)
    end
  end
end
