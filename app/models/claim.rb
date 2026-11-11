class Claim < ApplicationRecord
  class << self
    def ransackable_associations(_auth_object = nil)
      ['broker_carrier', 'broker_customer', 'shipment']
    end
  end

  before_save :set_balance_cents
  before_save :set_total_cents

  belongs_to :shipment

  has_many :claim_items, dependent: :destroy
  accepts_nested_attributes_for :claim_items, allow_destroy: true, reject_if: :all_blank

  has_many :items, through: :shipment

  has_one :broker_customer, through: :shipment

  monetize :balance_cents
  monetize :total_cents

  scope :paid, -> { where(balance_cents: ..0) }
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
