# frozen_string_literal: true

class UpchargeRule < ApplicationRecord
  scope :packaging, lambda { |packaging|
    where(packaging: packaging)
  }

  belongs_to :broker_customer
  belongs_to :packaging

  monetize :upcharge_cents
  validates_presence_of :min
end
