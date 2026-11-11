FactoryBot.define do
  factory :problem do
    association :assigned_to, factory: :user
    association :resolvable, factory: :shipment

    body { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    problematic_rule_code { Shipment.problematic_rule_codes.sample }
    title { Faker::Lorem.sentences(number: 1).first }

    after(:build) { |record| record.assigned_to = record.resolvable.dispatcher }
  end
end
