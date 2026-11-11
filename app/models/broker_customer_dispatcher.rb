class BrokerCustomerDispatcher < ApplicationRecord
  belongs_to :user
  belongs_to :broker_customer
end
