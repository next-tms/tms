# == Schema Information
#
# Table name: accessorials
#
# @!attribute id
#   @return []
# @!attribute code
#   @return [String]
# @!attribute fee
#   @return [Boolean]
# @!attribute freight_kit_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_accessorials_on_name  (name) UNIQUE
#
class Accessorial < ApplicationRecord
  after_create :create_broker_accessorials

  belongs_to :shipment_accessorial, optional: true

  scope :fee, -> { where(fee: true) }
  scope :service, -> { where.not(id: fee) }

  validates :name, presence: true, uniqueness: true

  def self.combined_accessorials(shipment:)
    Accessorial.distinct
               .where(
                 id: shipment.accessorials.pluck(:id) +
                     shipment.assumed_accessorials.pluck(:id)
               )
  end

  def self.combined_accessorial_freight_kit_codes(shipment:)
    combined_accessorials(shipment:).where.not(freight_kit_code: [nil, '']).map do |accessorial|
      accessorial.freight_kit_code.to_sym
    end
  end

  private

  def create_broker_accessorials
    BrokerAccessorial.create(accessorial: self, broker_only: false, code:, fee:, name:)
  end
end
