# Fetch Documents (Either BOL (Bill of Landing) or POD (Proof of Delivery)) from
# Interstellar API
class InterstellarDocumentService
  class << self
    def carrier_bol(shipment:)
      return nil if shipment.pro.blank? || shipment.carrier_bol.attached?

      broker_carrier = shipment.broker_carrier
      interstellar_document_response = InterstellarApiClient.fetch_bol(broker_carrier:, tracking_number: shipment.pro)

      return nil unless interstellar_document_response&.data.present?

      attach_document(type: :bol, document: interstellar_document_response, shipment: shipment)
      deliver_mail_to_contacts(shipment: shipment, type: :carrier_bol)
      resolve_problems(type: :missing_carrier_bol, shipment: shipment)

      true
    end

    def carrier_pod(shipment:)
      return nil if shipment.pro.blank? || shipment.carrier_pod.attached?

      broker_carrier = shipment.broker_carrier
      interstellar_document_response = InterstellarApiClient.fetch_pod(broker_carrier:, tracking_number: shipment.pro)

      return nil unless interstellar_document_response&.data.present?

      attach_document(type: :pod, document: interstellar_document_response, shipment: shipment)
      deliver_mail_to_contacts(shipment: shipment, type: :carrier_pod)
      resolve_problems(type: :missing_carrier_pod, shipment: shipment)

      true
    end

    private

    def attach_document(type:, document:, shipment:)
      attachment = shipment.send("carrier_#{type}")

      attachment.attach(
        io: StringIO.new(document.data),
        filename: "#{shipment.load_id} #{type.upcase} (Carrier).#{Rack::Mime::MIME_TYPES.invert[document.content_type]}",
        content_type: document.content_type
      )
    end

    def deliver_mail_to_contacts(shipment:, type:)
      contacts = Contact.where(id: shipment.broker_customer.document_preferences.where(kind: type.to_s).pluck(:contact_id))

      contacts.find_each do |contact|
        user = contact.user

        if user
          DocumentNotification.with(from_user: nil, to_contact: contact, shipment: shipment, document_type: type).deliver(user)
        else
          ContactMailer.send(type, from_user: nil, to_contact: contact, shipment: shipment).deliver_later
        end
      end
    end

    def resolve_problems(type:, shipment:)
      problem_type = ProblemType.find_by_code(type.to_s)
      problems = Problem.where(problem_type:, resolvable: shipment)

      return if problems.blank?

      problems.update_all(resolved_at: DateTime.current, resolved_by_id: nil)
    end
  end
end
