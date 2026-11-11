class Commission < ApplicationRecord
  class << self
    def ransackable_associations(_auth_object = nil)
      ['shipment', 'user']
    end
  end

  belongs_to :shipment
  belongs_to :user

  monetize :amount_cents

  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where.not(id: paid) }

  # @todo `change_column_null :commissions, :user_id, false

  def percent = shipment.profit.zero? ? 0 : (amount / shipment.profit).round(2)
end
