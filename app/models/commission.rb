# frozen_string_literal: true

class Commission < ApplicationRecord
  belongs_to :broker_customer_sales_rep
  belongs_to :shipment

  monetize :amount_cents

  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where.not(id: paid) }

  def percent
    (amount.to_f / shipment.profit.to_f).round(2)
  end
end
