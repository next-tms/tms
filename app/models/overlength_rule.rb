class OverlengthRule < ApplicationRecord
  belongs_to :broker_carrier

  monetize :cost_cents, allow_nil: false

  validate :validate_lengths, if: -> { min_length.present? }

  validates :min_length, presence: true

  def lengths_range
    min_length..(max_length || Float::INFINITY)
  end

  # @return [Measured::Length]
  def measured_max_length
    return if max_length.blank?

    Measured::Length.new(max_length, :inches)
  end

  # @return [Measured::Length, nil]
  def measured_min_length
    Measured::Length.new(min_length, :inches)
  end

  def overlap?(other_record)
    return false if other_record == self || other_record.broker_carrier != broker_carrier

    lengths_range.overlap?(other_record.lengths_range)
  end

  private

  def validate_lengths
    broker_carrier.overlength_rules.reject(&:marked_for_destruction?).each do |record|
      next unless overlap?(record)

      errors.add(:max_length, "conflicts with another #{model_name.human.downcase}")
      errors.add(:min_length, "conflicts with another #{model_name.human.downcase}")
    end
  end
end
