FactoryBot.define do
  factory :address do
    street { "MyString" }
    street2 { "MyString" }
    city { "MyString" }
    zip_code { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
    verification_info { "MyText" }
    original_attributes { "MyText" }
    updated_at { "2022-06-30 00:13:43" }
    ref { "MyString" }
    google_places_spot_cached { "MyText" }
    open_street_map_result_cached { "MyText" }
    google_places_spot_updated_at { "2022-06-30 00:13:43" }
    smarty_streets_result_updated_at { "2022-06-30 00:13:43" }
    open_street_map_result_updated_at { "2022-06-30 00:13:43" }
    standardized_address { }
    time_zone_name { "MyString" }

    before :create do |address|
      country = create(:country)
      region = create(:region, country: country)

      address.country = country
      address.region = region
    end
  end
end
