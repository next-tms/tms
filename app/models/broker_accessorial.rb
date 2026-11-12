class BrokerAccessorial < ApplicationRecord
  scope :blanket, -> { where(broker_customer: nil) }

  belongs_to :broker_customer, optional: true
  belongs_to :accessorial, optional: true

  validates :code, presence: true
  validates :name, presence: true

  monetize :flat_charge_cents, allow_nil: true
  monetize :upcharge_cents, allow_nil: true
end
