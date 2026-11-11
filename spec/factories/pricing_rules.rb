# == Schema Information
#
# Table name: pricing_rules
#
# @!attribute id
#   @return []
# @!attribute cost_per_pallet_cents
#   @return [Integer]
# @!attribute cost_per_pallet_currency
#   @return [String]
# @!attribute max_pallets
#   @return [Integer]
# @!attribute min_pallets
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_carrier_id
#   @return []
# @!attribute from_area_id
#   @return []
# @!attribute to_area_id
#   @return []
#
# Indexes
#
#  index_pricing_rules_on_broker_carrier_id  (broker_carrier_id)
#  index_pricing_rules_on_from_area_id       (from_area_id)
#  index_pricing_rules_on_max_pallets        (max_pallets)
#  index_pricing_rules_on_min_pallets        (min_pallets)
#  index_pricing_rules_on_to_area_id         (to_area_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (from_area_id => areas.id)
#  fk_rails_...  (to_area_id => areas.id)
#
FactoryBot.define do
  factory :pricing_rule do
    broker_carrier { create(:broker_carrier) }
    cost_per_pallet { Money.new(10_000) }
    from_area { Area.create!(name: 'California, US') }
    min_pallets { 1 }
    to_area { Area.create!(name: 'Texas, US') }
  end
end
