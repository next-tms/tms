# frozen_string_literal: true

# == Schema Information
#
# Table name: commissions
#
# @!attribute id
#   @return []
# @!attribute amount_cents
#   @return [Integer]
# @!attribute amount_currency
#   @return [String]
# @!attribute paid
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute shipment_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_commissions_on_shipment_id  (shipment_id)
#  index_commissions_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (user_id => users.id)
#
class Commission < ApplicationRecord
  belongs_to :user
  belongs_to :shipment

  monetize :amount_cents

  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where.not(id: paid) }

  # @todo `change_column_null :commissions, :user_id, false
  validates :user, presence: true

  def percent
    (amount.to_f / shipment.profit.to_f).round(2)
  end
end
