FactoryBot.define do
  factory :api_key do
    name { "#{Faker::App.name} #{SecureRandom.hex(4)}" }
    ttl { APIKey::MAX_TTL }
    user factory: :customer_user

    trait :carrier do
      user factory: :carrier_user
    end
  end
end
