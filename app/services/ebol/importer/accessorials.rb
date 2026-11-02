class EBOL::Importer::Accessorials
  attr_reader :codes, :shipment

  def initialize(codes, shipment)
    @codes = codes
    @shipment = shipment
  end

  def broker_accessorials
    shipment
      .broker_customer
      .eligible_broker_accessorials
      .joins(:accessorial)
      .where(accessorial: { freight_kit_code: codes.filter_map { |code| EBOL.freight_kit_code(code) } })
  end

  def shipment_broker_accessorials_attributes
    broker_accessorial_ids = broker_accessorials.ids
    removed, kept = mapped_shipment_broker_accessorials.partition do |shipment_broker_accessorial|
      broker_accessorial_ids.exclude?(shipment_broker_accessorial.broker_accessorial_id)
    end

    [
      *removed.map { |shipment_broker_accessorial| { _destroy: true, id: shipment_broker_accessorial.id } },
      *(broker_accessorial_ids - kept.map(&:broker_accessorial_id)).map { |broker_accessorial_id| { broker_accessorial_id: } }
    ]
  end

  def unsupported_codes
    supported_codes = broker_accessorials.includes(:accessorial).map do |broker_accessorial|
      broker_accessorial.accessorial.freight_kit_code
    end

    codes.reject { |code| supported_codes.include?(EBOL.freight_kit_code(code)) }
  end

  private

  def mapped_shipment_broker_accessorials
    shipment
      .shipment_broker_accessorials
      .joins(broker_accessorial: :accessorial)
      .where(accessorial: { freight_kit_code: EBOL::ACCESSORIAL_CODES.keys })
  end
end
