class CreateReceivableJob < ApplicationJob
  discard_on ActiveRecord::RecordNotUnique

  def perform(shipment)
    Shipment.transaction do
      shipment.lock!

      return unless shipment.reload.receivable?

      receivable = Receivable.build_from_shipment(shipment)
      return if receivable.total.zero?

      receivable.save

      return unless Setting.automatically_authorize_receivables

      receivable.update(authorized_at: DateTime.current)

      PushReceivableToAccountingJob.perform_later(receivable:) if Accounting.connected?
    end
  end
end
