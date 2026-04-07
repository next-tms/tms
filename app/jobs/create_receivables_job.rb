class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.reload.find_each do |shipment|
      CreateReceivableJob.perform_later(shipment)
    end
  end
end
