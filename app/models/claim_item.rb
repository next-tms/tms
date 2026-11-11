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
