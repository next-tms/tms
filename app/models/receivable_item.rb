class ReceivableItem < ApplicationRecord
  belongs_to :receivable
  monetize :charge_cents, allow_nil: true
  validates :description, presence: true
end
