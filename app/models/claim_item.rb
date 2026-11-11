# == Schema Information
#
# Table name: claim_items
#
# @!attribute id
#   @return []
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute notes
#   @return [String]
# @!attribute payee_type
#   @return [String]
# @!attribute total_cents
#   @return [Integer]
# @!attribute total_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute claim_id
#   @return []
# @!attribute payee_id
#   @return []
#
# Indexes
#
#  index_claim_items_on_claim_id  (claim_id)
#  index_claim_items_on_payee     (payee_type,payee_id)
#
# Foreign Keys
#
#  fk_rails_...  (claim_id => claims.id)
#
# @!attribute id
#   @return []
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute notes
#   @return [String]
# @!attribute payee_type
#   @return [String]
# @!attribute total_cents
#   @return [Integer]
# @!attribute total_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute claim_id
#   @return []
# @!attribute payee_id
#   @return []
#
# Indexes
#
#  index_claim_items_on_claim_id  (claim_id)
#  index_claim_items_on_payee     (payee_type,payee_id)
#
# Foreign Keys
#
#  fk_rails_...  (claim_id => claims.id)
#
class ClaimItem < ApplicationRecord
  before_save :set_balance_cents

  belongs_to :claim
  belongs_to :payee, polymorphic: true

  monetize :balance_cents, allow_nil: false
  monetize :total_cents, allow_nil: false

  private

  def set_balance_cents
    return if persisted? || total_cents.nil?

    self.balance_cents = total_cents
  end
end
