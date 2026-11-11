class DocumentPreference < ApplicationRecord
  belongs_to :broker_customer, optional: true
  belongs_to :contact

  enum :kind, { carrier_bol: 'carrier_bol', carrier_pod: 'carrier_pod' }

  validates :kind, presence: true
end
