# frozen_string_literal: true

# Fetch Documents (Either BOL (Bill of Landing) or POD (Proof of Delivery)) from
# FreightKit API
class FreightKitDocumentService
  class << self
    def carrier_bol(shipment:)
      return if shipment.pro.blank? || shipment.carrier_bol.attached?

      broker_carrier = shipment.broker_carrier
      transponder_document_response = TransponderService.new(shipment:).document(document_type: :bol)

      return nil if transponder_document_response[:data].blank?

      attach_document(type: :bol, document: transponder_document_response, shipment:)
      deliver_mail_to_contacts(shipment:, type: :carrier_bol)
      shipment.problematic!

      true
    end

    def carrier_pod(shipment:)
      return if shipment.pro.blank? || shipment.carrier_pod.attached?

      broker_carrier = shipment.broker_carrier
      transponder_document_response = TransponderService.new(shipment:).document(document_type: :pod)

      return nil if transponder_document_response[:data].blank?

      attach_document(type: :pod, document: transponder_document_response, shipment:)
      deliver_mail_to_contacts(shipment:, type: :carrier_pod)
      shipment.problematic!

      true
    end

    def reattach_document(shipment:, document_type:)
      return unless %i[bol pod].include?(document_type)

      transponder_document_response = TransponderService.new(shipment:).document(document_type: document_type.to_sym)
      return nil if transponder_document_response[:data].blank?

      document = shipment.send("carrier_#{document_type}")
      document.purge

      shipment.reload
      attach_document(type: :bol, document: freight_kit_document_response, shipment:)
    end

    private

    def attach_document(type:, document:, shipment:)
      attachment = shipment.send("carrier_#{type}")

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(document[:data]),
        filename: "#{shipment.load_id} #{type.upcase} (Carrier)#{Rack::Mime::MIME_TYPES.invert[document[:contentType]]}",
        content_type: document[:contentType],
      )
      attachment.attach(blob)

      shipment.problematic!
    end

    def deliver_mail_to_contacts(shipment:, type:)
      contacts = Contact.where(id: shipment.broker_customer.document_preferences.where(kind: type.to_s).pluck(:contact_id))

      contacts.find_each do |contact|
        user = contact.user

        if user
          DocumentNotification
          .with(
            from_user: nil,
            to_contact: contact,
            shipment:,
            document_type: type,
          )
          .deliver(user)

          next
        end

        ContactMailer.send(type, from_user: nil, to_contact: contact, shipment:).deliver_later
      end
    end
  end
end
