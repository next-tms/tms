# frozen_string_literal: true

class PickupsService
  def initialize(pickup:)
    @broker_carrier = pickup.shipment.broker_carrier
    @pickup = pickup
    @shipment = pickup.shipment
    @use_forced_freight_classes = !pickup.rate.with_calculated_freight_classes
  end

  def dispatch
    packages = @shipment.items.map do |item|
      item.as_interstellar_package(use_forced_freight_class: @use_forced_freight_classes)
    end

    response = nil

    interstellar_destination = @shipment.receiver_address.to_interstellar_shipping_address
    interstellar_destination.contact = Interstellar::Contact.new(
      company_name: @shipment.receiver_name,
      email: @shipment.receiver_contact_email,
      name: @shipment.receiver_contact_name,
      phone: @shipment.receiver_contact_phone,
    )

    interstellar_origin = @shipment.shipper_address.to_interstellar_shipping_address
    interstellar_origin.contact = Interstellar::Contact.new(
      company_name: @shipment.shipper_name,
      email: @shipment.shipper_contact_email,
      name: @shipment.shipper_contact_name,
      phone: @shipment.shipper_contact_phone,
    )

    interstellar_shipment = Interstellar::Shipment.new(
      accessorials:,
      declared_value_cents: @shipment.value_cents,
      destination: interstellar_destination,
      order_number: @shipment.shipper_reference,
      origin: interstellar_origin,
      packages:,
      po_number: @shipment.customer_reference,
      pro: @shipment.pro,
    )

    interstellar_dispatcher = Interstellar::Contact.new(
      email: @pickup.dispatcher.email,
      name: (@pickup.dispatcher.full_name.presence || 'Dispatcher'),
      phone: @pickup.dispatcher.phone,
    )

    error = nil

    begin
      response = InterstellarAPIClient.create_pickup(
        broker_carrier: @broker_carrier,
        delivery_from: @shipment.delivery_from,
        delivery_to: @shipment.delivery_by,
        dispatcher: interstellar_dispatcher,
        pickup_from: @shipment.pickup_from.in_time_zone(@shipment.shipper_address.time_zone),
        pickup_to: @shipment.pickup_by.in_time_zone(@shipment.shipper_address.time_zone),
        scac: @broker_carrier.carrier.scac,
        service: @shipment.applied_rate.interstellar_service_type.to_sym,
        shipment: interstellar_shipment,
      )
    rescue StandardError => e
      error = e
    end

    error ||= response&.error

    if error.present?
      if !Rails.env.development? && !error.is_a?(Interstellar::Error)
        attributes = {
          broker_carrier_id: @broker_carrier&.id,
          pickup_id: @pickup&.id,
          shipment_id: @pickup&.shipment_id,
          use_forced_freight_classes: @use_forced_freight_classes
        }

        Honeybadger.notify(error, attributes)
      end

      error_object = response || error

      @pickup.update(api_request: response.request, api_response: response.response, error_object:, updated_by: nil)
      Honeybadger.notify(error.message, pickup_attributes: @pickup.attributes) unless Rails.env.development?

      return false
    end

    pickup_confirmation = response.pickup_number
    @pickup.update(
      api_request: response.request,
      api_response: response.response,
      pickup_confirmation:,
      updated_by: nil,
    )

    return if response&.labels&.empty?

    paths = response.labels.map do |label|
      Tempfile.open do |_tempfile|
        f.binmode
        f.write(Base64.decode64(label.data))
        f.rewind

        f.path
      end
    end

    content_type = 'application/pdf'
    filename = "#{@shipment.load_id} Labels.pdf"
    io = PDFService.merge(*paths)

    blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)

    @shipment.carrier_label.attach(blob)
  end

  private

  def accessorials
    @accessorials ||= combined_accessorials.where.not(interstellar_code: [nil, '']).map do |accessorial|
      accessorial.interstellar_code.to_sym
    end
  end

  def combined_accessorials
    @combined_accessorials ||= Accessorial
                               .distinct
                               .where(
                                 id: @shipment.accessorials.pluck(:id) +
                                     @shipment.assumed_accessorials.pluck(:id),
                               )
  end

  def contact_name(key)
    case key
    when :receiver
      @shipment.receiver_contact_name || @shipment.receiver_name
    when :shipper
      @shipment.shipper_contact_name || @shipment.shipper_name
    end
  end

  def scac
    return @shipment.tracking_carrier.scac if @broker_carrier.carrier.acts_as_broker?

    @broker_carrier.carrier.scac
  end
end
