# frozen_string_literal: true

class ContactMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>'

  def broker_bol(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_bol,
      document_name: 'Bill of Lading',
      shipment: shipment,
      from_user: from_user,
      to_contact: to_contact,
    )
  end

  def broker_dispatch_sheet(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_dispatch_sheet,
      document_name: 'Scanned Bill of Lading',
      shipment: shipment,
      from_user: from_user,
      to_contact: to_contact,
    )
  end

  def broker_quote(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_quote,
      document_name: 'Quote',
      shipment: shipment,
      from_user: from_user,
      to_contact: to_contact,
    )
  end

  def carrier_bol(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.carrier_bol,
      document_name: 'Scanned Bill of Lading',
      shipment: shipment,
      from_user: from_user,
      to_contact: to_contact,
    )
  end

  def carrier_pod(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.carrier_pod,
      document_name: 'Proof of Delivery',
      shipment: shipment,
      from_user: from_user,
      to_contact: to_contact,
    )
  end

  private

  def send_document(document:, document_name:, from_user:, to_contact:, shipment:)
    attachments[document.filename.to_s] = {
      mime_type: document.content_type,
      content: document.download
    }

    mail(
      cc: pretty_email(from_user),
      from: "#{shipment.broker.name} <#{shipment.broker.customer_service_email}>",
      to: pretty_email(to_contact),
      subject: "#{document_name} for Load #{shipment.load_id}"
    )
  end

  def pretty_email(model)
    if model.label.blank?
      model.email
    else
      "#{model.label} <#{model.email}>"
    end
  end
end
