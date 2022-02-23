# frozen_string_literal: true

class ReceivablesMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>'

  def batch(broker_customer:, load_ids:, pdf_path:)
    @load_ids = load_ids.sort

    attachments[File.basename(pdf_path)] = {
      mime_type: 'application/pdf',
      content: File.read(pdf_path)
    }

    bcc = []
    broker_customer.broker.users.broker.find_each do |user|
      bcc << user.email if user.has_role?('accounts_receivable')
    end

    mail(
      from: "#{broker_customer.broker.name} <#{broker_customer.broker.robot_email}>",
      reply_to: broker_customer.broker.customer_service_email,
      to: pretty_email(broker_customer.receivables_contact),
      bcc:,
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
