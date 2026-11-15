module TransponderService
  class CreatePickup
    class << self
      def call(pickup)
        new(pickup).call
      end
    end

    attr_reader :declared_freight_classes, :pickup

    def initialize(pickup)
      raise ArgumentError, 'pickup must be a Pickup' unless pickup.is_a?(Pickup)

      raise ArgumentError, 'pickup.rate cannot be blank' if pickup.rate.blank?
      raise ArgumentError, 'pickup.broker_carrier cannot be blank' if pickup.broker_carrier.blank?

      @declared_freight_classes = pickup.rate.declared_freight_classes?
      @pickup = pickup
    end

    def call
      response = TransponderService.mutate(:create_pickup, pickup.broker_carrier, pickup)

      pickup_confirmation = response[:pickup_number]

      if pickup_confirmation.present?
        pickup.update!(api_request: response[:request], api_response: response[:response], pickup_confirmation:, updated_by: nil)
      end

      return true unless response[:labels].present? && response[:labels].any?

      paths = response[:labels].map do |label|
        Tempfile.open do |f|
          f.binmode
          f.write(Base64.decode64(label[:data]))
          f.rewind

          f.path
        end
      end

      content_type = 'application/pdf'
      filename = "#{pickup.shipment.load_id} Labels.pdf"
      io = PDFService.merge(*paths)

      blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

      pickup.shipment.carrier_label.attach(blob)

      true
    end

    private

    def accessorials
      @accessorials ||= Accessorial.combined_accessorial_freight_kit_codes(shipment:)
    end

    def contact_name(key)
      case key
      when :receiver
        pickup.shipment.receiver_contact_name || pickup.shipment.receiver_address.name
      when :shipper
        pickup.shipment.shipper_contact_name || pickup.shipment.shipper_address.name
      end
    end

    def scac
      return pickup.shipment.tracking_carrier.scac if pickup.broker_carrier.carrier.acts_as_broker?

      pickup.broker_carrier.carrier.scac
    end
  end
end
