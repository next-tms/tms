class UpchargeRule < ApplicationRecord
  audited

  scope :packaging, ->(packaging) { where(packaging:) }

  belongs_to :broker_customer
  belongs_to :packaging

  monetize :upcharge_cents
  validates :min, presence: true
end
