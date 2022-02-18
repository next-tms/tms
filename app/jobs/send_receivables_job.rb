# frozen_string_literal: true

class SendReceivablesJob < ApplicationJob
  def perform
    broker_customers = BrokerCustomer.distinct.where(id: Receivable.unsent.joins(:shipment).pluck(:broker_customer_id))

    broker_customers.find_each do |broker_customer|
      receivables = broker_customer.receivables.unsent.with_attached_invoice.order(:created_at)

      pdf = CombinePDF.new
      load_ids = []

      receivables.each do |receivable|
        next unless receivable.sendable?

        load_ids << receivable.shipment.load_id

        pdf << CombinePDF.load(receivable.invoice.url)
        pdf << CombinePDF.load(receivable.shipment.carrier_bol) if broker_customer.requires_carrier_bol_on_receivables?
        pdf << CombinePDF.load(receivable.shipment.carrier_pod) if broker_customer.requires_carrier_pod_on_receivables?
      end

      filename = "Batch Invoices - #{broker_customer.customer.name} #{DateTime.current.to_i}.pdf"
      path = File.join(Dir.tmpdir, filename)
      pdf.save(path)

      # Using deliver_now because PDF may not persist
      ReceivablesMailer.batch(broker_customer:, load_ids:, pdf_path: path).deliver_now
    end
  end
end
