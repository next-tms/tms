class Accessorial < ApplicationRecord
  class << self
    def combined_accessorials(shipment:)
      Accessorial.distinct.where(id: shipment.accessorials.pluck(:id) + shipment.assumed_accessorials.pluck(:id))
    end

    def combined_accessorial_freight_kit_codes(shipment:)
      combined_accessorials(shipment:).where.not(freight_kit_code: [nil, '']).map { |accessorial| accessorial.freight_kit_code.to_sym }
    end
  end

  after_create :create_broker_accessorials

  belongs_to :shipment_accessorial, optional: true

  scope :fee, -> { where(fee: true) }
  scope :service, -> { where.not(id: fee) }

  validates :name, presence: true, uniqueness: true

  private

  def create_broker_accessorials
    BrokerAccessorial.create(accessorial: self, broker_only: false, code:, fee:, name:)
  end
end
