FactoryBot.define do
  factory :payment_transaction do
    balance_cents { Faker::Number.between(from: 100, to: 5_000) }
    broker_carrier
    due_on { Date.current }
    invoice { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
    shipment
  end
end
