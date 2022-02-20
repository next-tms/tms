# frozen_string_literal: true

class SendReceivablesJob < ApplicationJob
  def perform
    broker_customers = BrokerCustomer.distinct.where(id: Receivable.unsent.joins(:shipment).pluck(:broker_customer_id))
    order = :created_at

    broker_customers.find_each do |broker_customer|
      receivables = broker_customer.receivables.unsent.with_attached_invoice.order(order)
      sendable_receivable_ids = []

      pdf = CombinePDF.new
      load_ids = []

      receivables.each do |receivable|
        next unless receivable.sendable?

        load_ids << receivable.shipment.load_id
        sendable_receivable_ids << receivable.id

        pdf << CombinePDF.parse(receivable.invoice.download)
        pdf << CombinePDF.parse(receivable.shipment.carrier_bol.download) if broker_customer.requires_carrier_bol_on_receivables?
        pdf << CombinePDF.parse(receivable.shipment.carrier_pod.download) if broker_customer.requires_carrier_pod_on_receivables?
      end

      filename = "Batch Invoices - #{broker_customer.customer.name} #{DateTime.current.to_i}.pdf"
      path = File.join(Dir.tmpdir, filename)
      pdf.save(path)

      receivables = Receivable.where(id: sendable_receivable_ids).order(order)

      # Using deliver_now because PDF may not persist
      receivables.update_all(sent_at: DateTime.current) if ReceivablesMailer.batch(broker_customer:, load_ids:,
                                                                                   pdf_path: path).deliver_now
    end
  end
end
