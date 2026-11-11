FactoryBot.define do
  factory :carrier do
    sequence(:name) { |number| "#{Faker::Company.name} #{number}" }
    sequence(:scac) { |number| format('%04d', number % 10_000) }

    check_mailing_address_id { create(:address) }
    mc_number { Faker::Number.number.to_s[..5] }

    trait :saia do
      scac { 'SAIA' }
      transponder_id { '26a6a0c0-2e95-4835-ad73-4a3c8bb38cdd' }
    end

    trait :tql do
      acts_as_broker { true }
      consider_bol_and_pod_documents_same { true }
      scac { 'TQYL' }
      transponder_id { '8f0c3b52-6b1e-4b8e-9a51-3f2f0d7c1e44' }
    end
  end
end
