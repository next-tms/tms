# frozen_string_literal: true

class BrokerCustomerSalesRep < ApplicationRecord
  belongs_to :user
  belongs_to :broker_customer
end
