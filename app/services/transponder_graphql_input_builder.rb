# frozen_string_literal: true

class TransponderGraphqlInputBuilder
  attr_reader :shipment, :broker_carrier, :opts, :operation

  def initialize(shipment:, opts: {}, operation:, broker_carrier: nil)
    @shipment = shipment
    @broker_carrier = broker_carrier.presence || shipment.broker_carrier
    @opts = opts
    @operation = operation
  end

  def call
    args = send(operation)
    args.merge!(carrier_credentials)

    args
  end

  private

  def tracking
    { trackingNumber: shipment.pro }
  end

  def document
    { trackingNumber: shipment.pro, documentType: opts[:document_type].upcase }
  end

  def fetch_pro
    {
      pickupNumber: shipment.pickup_confirmation,
      pickupOn: shipment.pickup_on&.iso8601,
      dispatchedAt: shipment.dispatched_at&.iso8601
    }
  end

  def rates
    {
      pickupAt: (shipment.pickup_from.presence || DateTime.current.in_time_zone(shipment.shipper_address.time_zone) + 3.hours).iso8601,
      destination: shipment.receiver_address.as_graphql_input.merge(contact_details(:receiver)),
      origin: shipment.shipper_address.as_graphql_input.merge(contact_details(:shipper)),
      packages:,
      accessorials:
    }.compact
  end

  def create_pickup
    {
      delivery_from: shipment.delivery_from&.iso8601,
      delivery_to: shipment.delivery_by&.iso8601,
      pickup_from: shipment.pickup_from.in_time_zone(shipment.shipper_address.time_zone)&.iso8601,
      pickup_to: shipment.pickup_by.in_time_zone(shipment.shipper_address.time_zone)&.iso8601,
      service: :standard,
      value_cents: shipment.value_cents,
      destination: shipment.receiver_address.as_graphql_input.merge(contact_details(:receiver)),
      origin: shipment.shipper_address.as_graphql_input.merge(contact_details(:shipper)),
      order_number: shipment.shipper_reference,
      po_number: shipment.customer_reference,
      pro: shipment.pro,
      packages:,
      accessorials:,
      dispatcher: {
        email: opts[:pickup].dispatcher.email,
        name: (opts[:pickup].dispatcher.full_name.presence || 'Dispatcher'),
        phone: opts[:pickup].dispatcher.phone
      }
    }.compact
  end

  def carrier_credentials
    required_credential_types = broker_carrier.carrier.required_freight_kit_credentials
    credentials = required_credential_types.map do |type|
      FreightKitAPIClient::Services::BuildFreightKitCredential.new(
        type: type,
        broker_carrier:,
        return_hash: true,
      ).call.transform_keys { |k| k.to_s.camelize(:lower) }.compact
    end.compact

    { credentials:, scac: broker_carrier.scac }
  end

  def packages
    shipment.items.map do |item|
      item.as_graphql_input(use_forced_freight_classes: opts[:use_forced_freight_classes])
    end
  end

  def accessorials
    Accessorial.combined_accessorial_freight_kit_codes(shipment:)
  end

  def contact_details(type)
    {
      contact: {
        companyName: shipment.send("#{type}_name"),
        email: shipment.send("#{type}_contact_email"),
        name: shipment.send("#{type}_contact_name"),
        phone: shipment.send("#{type}_contact_phone")
      }
    }
  end
end
