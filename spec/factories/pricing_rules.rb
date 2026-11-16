FactoryBot.define do
  factory :pricing_rule do
    broker_carrier { create(:broker_carrier, carrier: Carrier.find_by(scac: 'SAIA') || create(:carrier, :saia)) }
    cost_per_pallet { Money.new(10_000) }
    lane_id { '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01' }
    min_pallets { 1 }
  end
end
