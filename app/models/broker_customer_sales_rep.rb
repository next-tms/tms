# frozen_string_literal: true

class BrokerCustomerSalesRep < ApplicationRecord
  belongs_to :user
  belongs_to :broker_customer

  monetize :commission_flat_cents
  validate :commission_flat_cents_or_commission_percent

  private

  def commission_flat_cents_or_commission_percent
    if [commission_flat_cents, commission_percent].compact.count == 0
       errors.add :base, 'Comission required'
     end
  end
end
