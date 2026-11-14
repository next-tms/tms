FactoryBot.define do
  factory :tracking_event do
    association :shipment

    at { Faker::Time.between(from: 2.weeks.ago, to: Time.current) }
    country_alpha2 { 'US' }
    event { create(:event) }
    region_iso31662 { 'US-CA' }
    time_zone_name { TZInfo::Timezone.all_data_zone_identifiers.sample }
  end
end
