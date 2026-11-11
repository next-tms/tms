FactoryBot.define do
  factory :event do
    name { Faker::Verb.past_participle.underscore }
    public_by_default { [true, false].sample }

    after(:build) { |record| record.active_shipping_code = record.name }
  end
end
