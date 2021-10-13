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
      broker_carrier: @shipment.broker_carrier,
      origin: @shipment.shipper_address.to_interstellar_shipping_address,
      destination: @shipment.receiver_address.to_interstellar_shipping_address,
      packages: packages,
      accessorials: accessorials,
      shipper_contact_name: contact_name(:shipper) || '',
      shipper_name: @shipment.shipper_name || '',
      shipper_phone: @shipment.shipper_contact_phone || '',
      receiver_contact_name: contact_name(:receiver),
      receiver_name: @shipment.receiver_name || '',
      receiver_phone: @shipment.receiver_contact_phone || ''
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
    @shipment.flattened_items.each do |item|
      package = item.as_interstellar_package(use_forced_freight_class: @use_forced_freight_classes)
      @packages << package
    end

    @packages
  end

  def accessorials
    return @accessorials if @accessorials

    @accessorials = []
    combined_accessorials.where.not(interstellar_code: [nil, '']).find_each do |accessorial|
      @accessorials << accessorial.interstellar_code.to_sym
    end

    @accessorials
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
end
