# == Schema Information
#
# Table name: receivable_items
#
# @!attribute id
#   @return []
# @!attribute charge_cents
#   @return [Integer]
# @!attribute charge_currency
#   @return [String]
# @!attribute description
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute receivable_id
#   @return []
#
# Indexes
#
#  index_receivable_items_on_receivable_id  (receivable_id)
#
# Foreign Keys
#
#  fk_rails_...  (receivable_id => receivables.id)
#
# @!attribute id
#   @return []
# @!attribute charge_cents
#   @return [Integer]
# @!attribute charge_currency
#   @return [String]
# @!attribute description
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute receivable_id
#   @return []
#
# Indexes
#
#  index_receivable_items_on_receivable_id  (receivable_id)
#
# Foreign Keys
#
#  fk_rails_...  (receivable_id => receivables.id)
#
class ReceivableItem < ApplicationRecord
  belongs_to :receivable
  monetize :charge_cents, allow_nil: true
  validates :description, presence: true
end
