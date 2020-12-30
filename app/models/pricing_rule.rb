# frozen_string_literal: true

class PricingRule < ApplicationRecord
  belongs_to :broker_carrier
  belongs_to :carrier_area

  monetize :cost_per_pallet_cents, allow_nil: false

  validates_presence_of :min_pallets
end
