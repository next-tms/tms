# frozen_string_literal: true

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
# @!attribute carrier_area_id
#   @return []
#
# Indexes
#
#  index_pricing_rules_on_broker_carrier_id  (broker_carrier_id)
#  index_pricing_rules_on_carrier_area_id    (carrier_area_id)
#  index_pricing_rules_on_max_pallets        (max_pallets)
#  index_pricing_rules_on_min_pallets        (min_pallets)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (carrier_area_id => carrier_areas.id)
#
class PricingRule < ApplicationRecord
  belongs_to :broker_carrier
  belongs_to :carrier_area

  monetize :cost_per_pallet_cents, allow_nil: false

  validates_presence_of :min_pallets
end
