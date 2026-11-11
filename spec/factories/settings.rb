FactoryBot.define do
  factory :setting do
    key { Faker::Alphanumeric.alpha.downcase }
    value { Faker::Alphanumeric.alpha }
  end
end
