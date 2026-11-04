FactoryBot.define do
  factory :payment do
    broker_carrier
    due_on { Date.current }
  end
end
