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

  validate :validate_cost_per_pallet
  validate :validate_pallets, if: -> { carrier_area.present? }

  validates :min_pallets, numericality: { greater_than: 0 }, presence: true, allow_nil: true

  def overlap?(other_record)
    return false if other_record == self || carrier_area.blank? || other_record.carrier_area != carrier_area

    pallets_range.overlap?(other_record.pallets_range)
  end

  def pallets_range
    (min_pallets || -1)..(max_pallets || Float::INFINITY)
  end

  private

  def validate_cost_per_pallet
    return if cost_per_pallet.positive?

    errors.add(:cost_per_pallet, 'must be positive')
  end

  def validate_pallets
    broker_carrier
    .pricing_rules
    .reject(&:marked_for_destruction?)
    .select { |record| record.carrier_area == carrier_area }
    .each do |record|
      next unless overlap?(record)

      errors.add(:max_pallets, "conflicts with another #{model_name.human.downcase}")
      errors.add(:min_pallets, "conflicts with another #{model_name.human.downcase}")
    end
  end
end
