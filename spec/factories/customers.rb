FactoryBot.define do
  factory :customer do
    legal_name { "#{name}, LLC" }
    sequence(:name) { |number| "#{Faker::Company.name} #{number}" }
  end
end
