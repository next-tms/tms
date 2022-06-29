FactoryBot.define do
  factory :region do
    country { create(:country) }
    name { "MyString" }
    abbreviation { "MyString" }
    updated_at { "2022-06-30 00:16:21" }
  end
end
