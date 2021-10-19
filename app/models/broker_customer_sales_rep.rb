# frozen_string_literal: true

class BrokerCustomerSalesRep < ApplicationRecord
  belongs_to :user
  belongs_to :broker_customer

  has_many :commissions
  has_many :shipments, through: :commissions

  monetize :commission_flat_cents

  validate :commission_flat_cents_or_commission_percent

  private

  def commission_flat_cents_or_commission_percent
    errors.add :base, 'Comission required' if [commission_flat_cents, commission_percent].compact.count == 0
  end
end
