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
    city { Faker::Address.city }
    google_places_spot_updated_at { Time.current }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    open_street_map_result_updated_at { Time.current }
    smarty_streets_result_updated_at { Time.current }
    street { Faker::Address.street_address }
    time_zone_name { Faker::Address.time_zone }
    zip_code { Faker::Address.zip }

    before :create do |address|
      country = create(:country)
      region = create(:region, country:)

      address.country = country
      address.region = region
    end
  end
end
