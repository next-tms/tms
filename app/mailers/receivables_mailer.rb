# frozen_string_literal: true

class ReceivablesMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>'

  def batch(broker_customer:, load_ids:, pdf_path:)
    @load_ids = load_ids.sort

    attachments[pdf_path] = {
      mime_type: 'application/pdf',
      content: File.open(pdf_path)
    }

    mail(
      from: "#{shipment.broker.name} <#{shipment.broker.robot_email}>",
      reply_to: broker_customer.broker.customer_service_email,
      to: pretty_email(broker_customer.receivables_contact),
      subject: load_ids.size > 1 ? 'Batch Invoices' : "Invoice #{load_ids[0]}"
    )
  end

  private

  def pretty_email(model)
    if model.label.blank?
      model.email
    else
      # Postmark doesn't like this format:
      # "#{model.label} <#{model.email}>"
      model.email
    end
  end
end
