# frozen_string_literal: true

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
# @!attribute interstellar_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
class Accessorial < ApplicationRecord
  after_create :create_broker_accessorials

  belongs_to :shipment_accessorial, optional: true

  scope :fee, -> { where(fee: true) }
  scope :service, -> { where.not(id: fee) }

  validates :name, presence: true, uniqueness: true

  private

  def create_broker_accessorials
    Broker.all.find_each do |broker|
      BrokerAccessorial.create(
        accessorial: self,
        broker: broker,
        broker_only: false,
        code: code,
        fee: fee,
        name: name
      )
    end
  end
end
