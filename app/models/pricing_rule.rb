class PricingRule < ApplicationRecord
  belongs_to :broker_carrier

  belongs_to_orm :lane, class_name: 'Transponder::ORM::Lane', foreign_key: :lane_id

  monetize :cost_per_pallet_cents, allow_nil: false

  validate :validate_cost_per_pallet
  validate :validate_lane_carrier, if: -> { broker_carrier.present? && will_save_change_to_lane_id? }
  validate :validate_pallets, if: -> { broker_carrier.present? && lane_id.present? }

  validates :min_pallets, numericality: { greater_than: 0 }, presence: true, allow_nil: true

  def overlap?(other_record) = other_record != self && same_lane?(other_record) && pallets_range.overlap?(other_record.pallets_range)
  def pallets_range = (min_pallets || -1)..(max_pallets || Float::INFINITY)
  def same_lane?(other_record) = lane_id.present? && other_record.lane_id == lane_id

  private

  def validate_cost_per_pallet = cost_per_pallet.positive? || errors.add(:cost_per_pallet, 'must be positive')
  def validate_lane_carrier = lane.nil? || broker_carrier.carrier.transponder_lanes.to_a.include?(lane) || errors.add(:lane, :inclusion)

  def validate_pallets
    broker_carrier
      .pricing_rules
      .reject(&:marked_for_destruction?)
      .select { |record| same_lane?(record) }
      .each do |record|
        next unless overlap?(record)

        errors.add(:max_pallets, "conflicts with another #{model_name.human.downcase}")
        errors.add(:min_pallets, "conflicts with another #{model_name.human.downcase}")
      end
  end
end
