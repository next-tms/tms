# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>'

  def broker_bol(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_bol,
      document_name: 'Bill of Lading',
      shipment:,
      from_user:,
      to_contact:,
    )
  end

  def broker_dispatch_sheet(from_user:, to_contact:, shipment:)
    # Prevent sending dispatch sheet to customers
    return if to_contact.companyable.is_a?(BrokerCustomer)

    @shipment = shipment

    send_document(
      document: shipment.broker_dispatch_sheet,
      document_name: 'Dispatch Sheet',
      shipment:,
      from_user:,
      to_contact:,
    )
  end

  def broker_quote(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_quote,
      document_name: 'Quote',
      shipment:,
      from_user:,
      to_contact:,
    )
  end

  def carrier_bol(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.carrier_bol,
      document_name: 'Scanned Bill of Lading',
      shipment:,
      from_user:,
      to_contact:,
    )
  end

  def carrier_pod(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.carrier_pod,
      document_name: 'Proof of Delivery',
      shipment:,
      from_user:,
      to_contact:,
    )
  end

  def broker_label(from_user:, to_contact:, shipment:)
    @shipment = shipment

    send_document(
      document: shipment.broker_label,
      document_name: 'Label',
      shipment:,
      from_user:,
      to_contact:,
    )
  end

  def from_notification
    @shipment = params[:shipment]
    @document_type = params[:record].to_notification.humanized_document_type

    send_document(
      document: params[:shipment].send(params[:document_type]),
      document_name: @document_type,
      shipment: params[:shipment],
      from_user: params[:from_user],
      to_contact: params[:to_contact],
    )
  end

  private

  def send_document(document:, document_name:, from_user:, to_contact:, shipment:)
    return unless document.attached?

    # Do not send email if document is not yet uploaded and prevent
    # Postmark::InvalidEmailAddressError: Zero-sized attachments not allowed.

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

    subject = "#{document_name} for Load #{shipment.load_id}"

    if shipment.pickup_confirmation && document_name == 'Dispatch Sheet'
      subject = "#{subject} with Pickup Confirmation ##{shipment.pickup_confirmation}"
    end

    mail(
      from: "#{shipment.broker.name} <#{shipment.broker.robot_email}>",
      cc:,
      reply_to: from_user.blank? ? nil : pretty_email(from_user),
      to: pretty_email(to_contact),
      subject: subject,
    )
  end

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
