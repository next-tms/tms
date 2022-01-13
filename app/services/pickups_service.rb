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
    error = nil

    interstellar_destination = @shipment.shipper_address.to_interstellar_shipping_address
    interstellar_destination.contact = Interstellar::Contact.new(
                                         company_name: @shipment.receiver_name,
                                         name: @shipment.receiver_contact_name
                                       )

    interstellar_origin = @shipment.shipper_address.to_interstellar_shipping_address
    interstellar_origin.contact = Interstellar::Contact.new(
                                    company_name: @shipment.shipper_name,
                                    name: @shipment.shipper_contact_name
                                  )

    interstellar_shipment = Interstellar::Shipment.new(
                              accessorials:,
                              destination: interstellar_destination,
                              order_number: @shipment.shipper_reference,
                              origin: interstellar_origin,
                              packages:,
                              po_number: @shipment.customer_reference
                            )

    interstellar_dispatcher = Interstellar::Contact.new(
                                name: @pickup.dispatcher.full_name.blank? ? 'Dispatcher' : @pickup.dispatcher.full_name,
                                phone: @pickup.dispatcher.phone,
                                email: @pickup.dispatcher.email
                              )

    delivery_from = (@shipment.delivery_from || @shipment.pickup_by + 5.business_days)

    begin
      response = InterstellarApiClient.create_pickup(
                   delivery_from: delivery_from.in_time_zone(@shipment.receiver_address.time_zone),
                   delivery_to: @shipment.delivery_by.in_time_zone(@shipment.receiver_address.time_zone),
                   dispatcher: interstellar_dispatcher,
                   pickup_from: @shipment.pickup_from.in_time_zone(@shipment.shipper_address.time_zone),
                   pickup_to: @shipment.pickup_by.in_time_zone(@shipment.shipper_address.time_zone),
                   scac: @broker_carrier.carrier.scac,
                   service: @shipment.applied_rate.interstellar_service_type.to_sym,
                   shipment: interstellar_shipment
                 )
    rescue StandardError => e
      error = e
    end

    if response.blank?
      @pickup.update(error_object: error, updated_by: nil)

      return false
    end

    @pickup.update(pickup_confirmation: response, updated_by: nil)
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
                                     @shipment.assumed_accessorials.pluck(:id)
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
