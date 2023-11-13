# frozen_string_literal: true

# == Schema Information
#
# Table name: claims
#
# @!attribute id
#   @return []
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute due_on
#   @return [Date]
# @!attribute total_cents
#   @return [Integer]
# @!attribute total_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_claims_on_due_on       (due_on)
#  index_claims_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#
class Claim < ApplicationRecord
  before_save :set_balance_cents
  before_save :set_total_cents

  belongs_to :shipment

  has_many :claim_items
  accepts_nested_attributes_for :claim_items, allow_destroy: true, reject_if: :all_blank

  has_many :items, through: :shipment

  has_one :broker_customer, through: :shipment

  monetize :balance_cents
  monetize :total_cents

  scope :paid, -> { where('balance_cents <= ?', 0) }
  scope :unpaid, -> { where('balance_cents > ?', 0) }

  private

  def set_balance_cents
    return if claim_items.none?

    self.balance_cents = claim_items.sum(&:balance_cents)
  end

  def set_total_cents
    return if claim_items.none?

    self.total_cents = claim_items.sum(&:total_cents)
  end
end
