# frozen_string_literal: true

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
