# frozen_string_literal: true

# == Schema Information
#
# Table name: addresses
#
# @!attribute id
#   @return []
# @!attribute city
#   @return [String]
# @!attribute google_places_spot_cached
#   @return [String]
# @!attribute google_places_spot_updated_at
#   @return [Time]
# @!attribute latitude
#   @return []
# @!attribute longitude
#   @return []
# @!attribute open_street_map_result_cached
#   @return [String]
# @!attribute open_street_map_result_updated_at
#   @return [Time]
# @!attribute original_attributes
#   @return [String]
# @!attribute ref
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute verification_info
#   @return [String]
# @!attribute zip_code
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return [Integer]
# @!attribute region_id
#   @return []
# @!attribute standardized_address_id
#   @return []
#
# Indexes
#
#  index_addresses_on_country_id               (country_id)
#  index_addresses_on_region_id                (region_id)
#  index_addresses_on_standardized_address_id  (standardized_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (region_id => regions.id)
#  fk_rails_...  (standardized_address_id => standardized_addresses.id)
#
FactoryBot.define do
  factory :address do
    street { 'MyString' }
    street2 { 'MyString' }
    city { 'MyString' }
    zip_code { 'MyString' }
    latitude { '9.99' }
    longitude { '9.99' }
    verification_info { 'MyText' }
    original_attributes { 'MyText' }
    updated_at { '2022-06-30 00:13:43' }
    ref { 'MyString' }
    google_places_spot_cached { 'MyText' }
    open_street_map_result_cached { 'MyText' }
    google_places_spot_updated_at { '2022-06-30 00:13:43' }
    smarty_streets_result_updated_at { '2022-06-30 00:13:43' }
    open_street_map_result_updated_at { '2022-06-30 00:13:43' }
    standardized_address {}
    time_zone_name { 'MyString' }

    before :create do |address|
      country = create(:country)
      region = create(:region, country:)

      address.country = country
      address.region = region
    end
  end
end
