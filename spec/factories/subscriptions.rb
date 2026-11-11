FactoryBot.define do
  factory :subscription do
    association :contact
    association :record, factory: :receivable
  end
end
