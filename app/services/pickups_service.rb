# frozen_string_literal: true

class PickupsService
  def initialize(broker_carrier:, shipment:)
    @broker_carrier = broker_carrier
    @shipment = shipment
  end

  def to_pickup
    InterstellarApiClient.create_pickup(
      accessorials: accessorials,
      broker_carrier: @broker_carrier,
      destination: @shipment.receiver_address.to_interstellar_shipping_address,
      origin: @shipment.shipper_address.to_interstellar_shipping_address,
      packages: packages,
      receiver_contact_name: shipment.receiver_contact_name,
      shipper_contact_name: shipment.shipper_contact_name
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

  def items
    @items ||= @shipment.items
  end

  def packages
    return @packages if @packages

    @packages = []
    @shipment.flattened_items.each do |item|
      package = item.as_interstellar_package(use_forced_freight_class: !@shipment.applied_rate.with_calculated_freight_classes)
      @packages << package
    end

    @packages
  end
end
