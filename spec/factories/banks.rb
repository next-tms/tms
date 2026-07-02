FactoryBot.define do
  factory :bank do
    account_number { Faker::Bank.account_number }
    broker { create(:broker) }
    kind { :checking }
    name { Faker::Bank.name }
  end
end
