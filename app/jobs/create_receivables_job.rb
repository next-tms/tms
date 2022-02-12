# frozen_string_literal: true

class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.find_each do |shipment|
      CreateReceivableJob.perform_later(shipment)
    end
  end
end
