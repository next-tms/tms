class PreferredBrokerCarrier < ApplicationRecord
  belongs_to :broker_carrier
  belongs_to :broker_customer
end
