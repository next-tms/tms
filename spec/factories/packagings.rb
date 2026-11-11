FactoryBot.define do
  factory :packaging do
    name { Faker::Name.name }
    freight_kit_type { 'MyString' }
  end
end
