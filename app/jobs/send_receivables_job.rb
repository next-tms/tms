# frozen_string_literal: true

class SendReceivablesJob < ApplicationJob
  def perform
    broker_customers = BrokerCustomer.distinct.where(id: Receivable.unsent.joins(:shipment).pluck(:broker_customer_id))
    order = :created_at

    broker_customers.where.not(receivables_schedule: :immediately).find_each do |broker_customer|
      receivables = broker_customer.receivables.unpaid.unsent.with_attached_invoice.order(order).select(&:sendable?)
      next if receivables.none?

      paths = []
      receivables.each do |receivable|
        paths << DownloadAttachmentService.call(receivable.invoice).path

        if broker_customer.requires_carrier_bol_on_receivables?
          paths << DownloadAttachmentService.call(receivable.shipment.carrier_bol).path
        end

        next unless broker_customer.requires_carrier_pod_on_receivables?

        paths << DownloadAttachmentService.call(receivable.shipment.carrier_pod).path
      end

      load_ids = receivables.map { |receivable| receivable.shipment.load_id }
      pdf = PDFService.merge(*paths)
      pdf_filename = ActiveStorage::Filename.new("Batch Invoices - #{broker_customer.customer.name}.pdf").sanitized

      next unless ReceivablesMailer.batch(broker_customer:, load_ids:, pdf:, pdf_filename:).deliver_now

      sent_at = Time.current
      receivables.map { |receivable| receivable.update!(sent_at:) }
    end

    broker_customers.where(receivables_schedule: :immediately).find_each do |broker_customer|
      receivables = broker_customer.receivables.unsent.with_attached_invoice.order(order).select(&:sendable?)

      receivables.each do |receivable|
        paths = []
        paths << DownloadAttachmentService.call(receivable.invoice).path

        if broker_customer.requires_carrier_bol_on_receivables?
          paths << DownloadAttachmentService.call(receivable.shipment.carrier_bol).path
        end

        if broker_customer.requires_carrier_pod_on_receivables?
          paths << DownloadAttachmentService.call(receivable.shipment.carrier_pod).path
        end

        load_ids = [ receivable.shipment.load_id ]
        pdf = PDFService.merge(*paths)
        pdf_filename = ActiveStorage::Filename.new("#{receivable.shipment.load_id} Invoice.pdf").sanitized

        next unless ReceivablesMailer.batch(broker_customer:, load_ids:, pdf:, pdf_filename:).deliver_now

        receivable.update!(sent_at: Time.current)
      end
    end
  end
end
