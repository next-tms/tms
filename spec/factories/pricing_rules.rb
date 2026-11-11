FactoryBot.define do
  factory :pricing_rule do
    broker_carrier { create(:broker_carrier) }
    cost_per_pallet { Money.new(10_000) }
    from_area { Area.create!(name: 'California, US') }
    min_pallets { 1 }
    to_area { Area.create!(name: 'Texas, US') }
  end
end
