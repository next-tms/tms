# frozen_string_literal: true

FactoryBot.define do
  factory :packaging do
    name { Faker::Name.name }
    interstellar_type { 'MyString' }
  end
end
