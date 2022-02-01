# frozen_string_literal: true

class ContactMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>'

  def broker_bol(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_bol,
      document_name: 'Bill of Lading',
      shipment:,
      from_user:,
      to_contact:
    )
  end

  def broker_dispatch_sheet(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_dispatch_sheet,
      document_name: 'Dispatch Sheet',
      shipment:,
      from_user:,
      to_contact:
    )
  end

  def broker_quote(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_quote,
      document_name: 'Quote',
      shipment:,
      from_user:,
      to_contact:
    )
  end

  def carrier_bol(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.carrier_bol,
      document_name: 'Scanned Bill of Lading',
      shipment:,
      from_user:,
      to_contact:
    )
  end

  def carrier_pod(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.carrier_pod,
      document_name: 'Proof of Delivery',
      shipment:,
      from_user:,
      to_contact:
    )
  end

  private

  def send_document(document:, document_name:, from_user:, to_contact:, shipment:)
    attachments[document.filename.to_s] = {
      mime_type: document.content_type,
      content: document.download
    }

    # Avoid SendGrid::DuplicatePersonalizationError
    cc = if from_user.is_a?(User)
           if from_user.email == to_contact.email
             nil
           else
             pretty_email(from_user)
           end
         end

    mail(
      from: "#{shipment.broker.name} <#{shipment.broker.robot_email}>",
      cc:,
      reply_to: from_user.blank? ? nil : pretty_email(from_user),
      to: pretty_email(to_contact),
      subject: "#{document_name} for Load #{shipment.load_id}"
    )
  end

  def pretty_email(model)
    if model.label.blank?
      model.email
    else
      # Temporarily disable due to Rollbar #34
      # "#{model.label} <#{model.email}>"
      model.email
    end
  end
end
