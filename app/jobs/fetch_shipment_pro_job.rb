# frozen_string_literal: true

class FetchShipmentProJob < ApplicationJob
  def perform(shipment)
    shipment.fetch_pro
  end
end
