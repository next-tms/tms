FactoryBot.define do
  factory :broker_customer do
    customer { create(:customer) }
    office_address { create(:address) }
    primary_pickup_address { create(:address) }

    after(:build) { |record| record.receivables_contact = build(:contact, companyable: record) }
  end
end
