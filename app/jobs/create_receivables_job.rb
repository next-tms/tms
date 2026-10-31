class CreateReceivablesJob < ApplicationJob
  def perform
    Shipment.receivable.reload.find_each { |shipment| CreateReceivableJob.perform_later(shipment) }
  end
end
