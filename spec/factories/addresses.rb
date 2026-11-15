FactoryBot.define do
  factory :address do
    city { Faker::Address.city }
    country_alpha2 { 'US' }
    google_places_spot_updated_at { Time.current }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    name { Faker::Company.name }
    open_street_map_result_updated_at { Time.current }
    region_iso31662 { 'US-CA' }
    smarty_streets_result_updated_at { Time.current }
    street { Faker::Address.street_address }
    time_zone_name { TZInfo::Timezone.all_data_zone_identifiers.sample }
    zip_code { Faker::Address.zip }
  end
end
