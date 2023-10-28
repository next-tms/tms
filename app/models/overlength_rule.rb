# frozen_string_literal: true

# == Schema Information
#
# Table name: overlength_rules
#
# @!attribute id
#   @return []
# @!attribute cost_cents
#   @return [Integer]
# @!attribute cost_currency
#   @return [String]
# @!attribute max_length
#   @return [Integer]
# @!attribute min_length
#   @return [Integer]
# @!attribute broker_carrier_id
#   @return []
#
# Indexes
#
#  index_overlength_rules_on_broker_carrier_id  (broker_carrier_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#
class OverlengthRule < ApplicationRecord
  belongs_to :broker_carrier
  monetize :cost_cents, allow_nil: false

  validates :min_length, presence: true

  # @return [Measured::Length]
  def measured_max_length
    return if max_length.blank?

    Measured::Length.new(max_length, :inches)
  end

  # @return [Measured::Length, nil]
  def measured_min_length
    Measured::Length.new(min_length, :inches)
  end
end
