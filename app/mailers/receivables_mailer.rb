# frozen_string_literal: true

class ReceivablesMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>'

  def batch(broker_customer:, load_ids:, pdf:, pdf_filename:)
    @load_ids = load_ids.sort

    attachments[pdf_filename] = {
      mime_type: 'application/pdf',
      content: pdf.to_pdf
    }

    bcc = []
    broker_customer.broker.users.broker.active.find_each do |user|
      bcc << user.email if user.role?(:accounts_receivable)
    end

    # cc = broker_customer.receivables_contacts.map do |contact|
    #   next if contact == broker_customer.receivables_contact

    #   pretty_email(contact)
    # end.compact

    mail(
      from: "#{broker_customer.broker.name} <#{broker_customer.broker.robot_email}>",
      reply_to: broker_customer.broker.customer_service_email,
      to: pretty_email(broker_customer.receivables_contact),
      bcc:,
      subject: load_ids.size > 1 ? 'Batch Invoices' : "Invoice #{load_ids[0]}",
    )
  end

  private

  def pretty_email(model)
    # return model.email if model.label.blank?
    #
    # Postmark doesn't like this format:
    # "#{model.label} <#{model.email}>"

    model.email
  end
end
