# frozen_string_literal: true

class PickupsService
  def initialize(pickup:)
    @broker_carrier = pickup.shipment.broker_carrier
    @pickup = pickup
    @shipment = pickup.shipment
    @use_forced_freight_classes = !pickup.rate.with_calculated_freight_classes
  end

  def dispatch
    error = nil

    begin
      response = TransponderService.new(shipment:).create_pickup(pickup:)
    rescue StandardError => e
      error = e
    end

    error ||= response.dig(:response, :error, :errormessage) || response[:error]

    if error.present?
      if !Rails.env.development? && !error.is_a?(FreightKit::Error)
        attributes = {
          broker_carrier_id: @broker_carrier&.id,
          pickup_id: @pickup&.id,
          shipment_id: @pickup&.shipment_id,
          use_forced_freight_classes: @use_forced_freight_classes
        }

        Honeybadger.notify(error, attributes)
      end

      error_object = response || error

      @pickup.update(api_request: response[:request], api_response: response[:response], error_object:, updated_by: nil)
      Honeybadger.notify(error, pickup_attributes: @pickup.attributes) unless Rails.env.development?

      return false
    end

    pickup_confirmation = response[:pickupNumber]
    @pickup.update(
      api_request: response[:request],
      api_response: response[:response],
      pickup_confirmation:,
      updated_by: nil,
    )

    return if response[:labels]&.empty?

    paths = response[:labels].map do |label|
      Tempfile.open do |_tempfile|
        f.binmode
        f.write(Base64.decode64(label[:data]))
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
    @accessorials ||= Accessorial.combined_accessorial_freight_kit_codes(shipment: @shipment)
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

#   // Old Dispatch Code using FreightKit
#   // TODO: Remove After Regression Testing
#   def dispatch
#     packages = @shipment.items.map do |item|
#       item.as_freight_kit_package(use_forced_freight_class: @use_forced_freight_classes)
#     end
#
#     response = nil
#
#     freight_kit_destination = @shipment.receiver_address.to_freight_kit_shipping_address
#     freight_kit_destination.contact = FreightKit::Contact.new(
#       company_name: @shipment.receiver_name,
#       email: @shipment.receiver_contact_email,
#       name: @shipment.receiver_contact_name,
#       phone: @shipment.receiver_contact_phone,
#     )
#
#     freight_kit_origin = @shipment.shipper_address.to_freight_kit_shipping_address
#     freight_kit_origin.contact = FreightKit::Contact.new(
#       company_name: @shipment.shipper_name,
#       email: @shipment.shipper_contact_email,
#       name: @shipment.shipper_contact_name,
#       phone: @shipment.shipper_contact_phone,
#     )
#
#     freight_kit_shipment = FreightKit::Shipment.new(
#       accessorials:,
#       declared_value_cents: @shipment.value_cents,
#       destination: freight_kit_destination,
#       order_number: @shipment.shipper_reference,
#       origin: freight_kit_origin,
#       packages:,
#       po_number: @shipment.customer_reference,
#       pro: @shipment.pro,
#     )
#
#     freight_kit_dispatcher = FreightKit::Contact.new(
#       email: @pickup.dispatcher.email,
#       name: (@pickup.dispatcher.full_name.presence || 'Dispatcher'),
#       phone: @pickup.dispatcher.phone,
#     )
#
#     error = nil
#
#     begin
#       response = FreightKitAPIClient.create_pickup(
#         broker_carrier: @broker_carrier,
#         delivery_from: @shipment.delivery_from,
#         delivery_to: @shipment.delivery_by,
#         dispatcher: freight_kit_dispatcher,
#         pickup_from: @shipment.pickup_from.in_time_zone(@shipment.shipper_address.time_zone),
#         pickup_to: @shipment.pickup_by.in_time_zone(@shipment.shipper_address.time_zone),
#         scac: @broker_carrier.carrier.scac,
#         service: @shipment.applied_rate.freight_kit_service_type.to_sym,
#         shipment: freight_kit_shipment,
#       )
#     rescue StandardError => e
#       error = e
#     end
#
#     error ||= response&.error
#
#     if error.present?
#       if !Rails.env.development? && !error.is_a?(FreightKit::Error)
#         attributes = {
#           broker_carrier_id: @broker_carrier&.id,
#           pickup_id: @pickup&.id,
#           shipment_id: @pickup&.shipment_id,
#           use_forced_freight_classes: @use_forced_freight_classes
#         }
#
#         Honeybadger.notify(error, attributes)
#       end
#
#       error_object = response || error
#
#       @pickup.update(api_request: response&.request, api_response: response&.response, error_object:, updated_by: nil)
#       Honeybadger.notify(error.message, pickup_attributes: @pickup.attributes) unless Rails.env.development?
#
#       return false
#     end
#
#     pickup_confirmation = response.pickup_number
#     @pickup.update(
#       api_request: response.request,
#       api_response: response.response,
#       pickup_confirmation:,
#       updated_by: nil,
#     )
#
#     return if response&.labels&.empty?
#
#     paths = response.labels.map do |label|
#       Tempfile.open do |_tempfile|
#         f.binmode
#         f.write(Base64.decode64(label.data))
#         f.rewind
#
#         f.path
#       end
#     end
#
#     content_type = 'application/pdf'
#     filename = "#{@shipment.load_id} Labels.pdf"
#     io = PDFService.merge(*paths)
#
#     blob = ActiveStorage::Blob.create_and_upload!(content_type:, filename:, io:)
#
#     @shipment.carrier_label.attach(blob)
#   end
