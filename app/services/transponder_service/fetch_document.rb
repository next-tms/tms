module TransponderService
  class FetchDocument
    class << self
      def call(shipment, document_type)
        new(shipment, document_type).call
      end
    end

    DOCUMENT_TYPES = %i[bol pod].freeze

    attr_reader :document_type, :shipment

    def initialize(shipment, document_type)
      if DOCUMENT_TYPES.exclude?(document_type)
        message = "document_type must be one of #{DOCUMENT_TYPES.join(', ')}"
        raise ArgumentError, message
      end

      raise ArgumentError, 'shipment must be a Shipment' unless shipment.is_a?(Shipment)

      @document_type = document_type
      @shipment = shipment
    end

    # @return [Boolean]
    def call
      return false if shipment.pro.blank? || attachment.attached?

      response = TransponderService.query(
        :fetch_document,
        shipment.broker_carrier,
        shipment,
        document_type:
      )

      return false if response[:document].blank?

      attach_document(response[:document])
      deliver_mail_to_contacts

      shipment.problematic!

      true
    end

    private

    def attachment
      @attachment ||= shipment.public_send("carrier_#{document_type}")
    end

    def attach_document(transponder_document)
      content_type = transponder_document[:content_type]
      io = StringIO.new(Base64.decode64(transponder_document[:data_base64]))

      basename = [shipment.load_id, document_type.to_s.upcase, '(Carrier)'].join(' ')
      ext = Rack::Mime::MIME_TYPES.invert[content_type]
      filename = [basename, ext].join('.')

      blob = ActiveStorage::Blob.create_and_upload!(io:, filename:, content_type:)
      attachment.attach(blob)

      shipment.problematic!
    end

    def deliver_mail_to_contacts
      type = case document_type
             when :bol then :carrier_bol
             when :pod then :carrier_pod
             end

      contacts = Contact
                 .where(
                   id: shipment
                       .broker_customer
                       .document_preferences
                       .where(kind: type.to_s)
                       .pluck(:contact_id)
                 )
      contacts.find_each do |contact|
        user = contact.user

        if user
          DocumentNotifier
            .with(
              from_user: nil,
              to_contact: contact,
              shipment:,
              document_type: type
            )
            .deliver(user)

          next
        end

        ContactMailer.public_send(type, from_user: nil, to_contact: contact, shipment:).deliver_later
      end
    end
  end
end
