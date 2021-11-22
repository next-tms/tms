# frozen_string_literal: true

class PickupsService
  def initialize(pickup:)
    @broker_carrier = pickup.shipment.broker_carrier
    @pickup = pickup
    @shipment = pickup.shipment
    @use_forced_freight_classes = !pickup.rate.with_calculated_freight_classes
  end

  def dispatch
    response = InterstellarApiClient.create_pickup(
      broker_carrier: @broker_carrier,
      accessorials: accessorials,
      customer_reference: @shipment.customer_reference,
      delivery_from: @shipment.delivery_from || @shipment.pickup_by + 5.business_days,
      delivery_to: @shipment.delivery_by,
      destination: @shipment.receiver_address.to_interstellar_shipping_address,
      origin: @shipment.shipper_address.to_interstellar_shipping_address,
      packages: packages,
      pickup_from: @shipment.pickup_from,
      pickup_to: @shipment.pickup_by,
      receiver_contact_name: contact_name(:receiver),
      receiver_name: @shipment.receiver_name || '',
      receiver_phone: @shipment.receiver_contact_phone || '',
      scac: scac,
      service: @shipment.applied_rate.interstellar_service_type.to_sym,
      shipper_contact_name: contact_name(:shipper) || '',
      shipper_name: @shipment.shipper_name || '',
      shipper_phone: @shipment.shipper_contact_phone || '',
      shipper_reference: @shipment.shipper_reference
    )

    if response.blank?
      @pickup.update(
        error: 'API Error: Carrier returned blank response',
        updated_by: nil
      )
      return false
    end

    @pickup.update(
      pickup_confirmation: response,
      updated_by: nil
    )
  end

  private

  def accessorials
    return @accessorials if @accessorials

    @accessorials = []
    combined_accessorials.where.not(interstellar_code: [nil, '']).find_each do |accessorial|
      @accessorials << accessorial.interstellar_code.to_sym
    end

    @accessorials
  end

  def combined_accessorials
    @combined_accessorials ||= Accessorial
                               .distinct
                               .where(
                                 id: @shipment.accessorials.pluck(:id) +
                                     @shipment.assumed_accessorials.pluck(:id)
                               )
  end

  def new_pickup
    Pickup.new(
      accessorials: combined_accessorials,
      broker_carrier: @broker_carrier,
      broker_customer: @shipment.broker_customer,
      shipment_fingerprint: @shipment.fingerprint,
      shipment: @shipment,
      with_calculated_freight_classes: !@use_forced_freight_classes
    )
  end

  def packages
    return @packages if @packages

    @packages = []
    @shipment.items.each do |item|
      package = item.as_interstellar_package(use_forced_freight_class: @use_forced_freight_classes)
      @packages << package
    end

    @packages
  end

  def items
    @items ||= @shipment.items
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
