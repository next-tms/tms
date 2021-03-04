# frozen_string_literal: true

class BrokerCustomerSalesRep < ApplicationRecord
  belongs_to :user
  belongs_to :broker_customer

  monetize :commission_flat_cents

  validates :commission_percent, presence: true
end
