# frozen_string_literal: true

class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.find_each do |shipment|
      receivable = Receivable.build_from_shipment(shipment)
      receivable.save
    end
  end
end
