# frozen_string_literal: true

class BrokerCustomerContact < ApplicationRecord
  belongs_to :broker_customer
  belongs_to :contact

  accepts_nested_attributes_for :contact
end
