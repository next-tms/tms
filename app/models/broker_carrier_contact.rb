class BrokerCarrierContact < ApplicationRecord
  belongs_to :broker_carrier
  belongs_to :contact

  accepts_nested_attributes_for :contact
end
