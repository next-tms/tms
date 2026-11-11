FactoryBot.define do
  factory :receivable do
    authorized_at { Time.current }
    due_by { 2.weeks.from_now }
    shipment do
      broker_customer = association(
        :broker_customer,
        requires_carrier_bol_on_receivables: false,
        requires_carrier_pod_on_receivables: false
      )
      association(:shipment, broker_customer:)
    end
    total_cents { Faker::Number.between(from: 100, to: 5_000).ceil }
    total_currency { Faker::Currency.code }
  end
end
