class EBOL::Importer::Accessorials
  attr_reader :codes, :shipment

  def initialize(codes, shipment)
    @codes = codes
    @shipment = shipment
  end

  def accessorials
    @accessorials ||= Accessorial.with_transponder_codes(
      codes.filter_map { |code| EBOL.transponder_code(code) },
      broker_customer: shipment.broker_customer
    )
  end

  def shipment_accessorials_attributes
    transponder_codes = accessorials.map(&:transponder_code)
    removed, kept = mapped_shipment_accessorials.partition do |shipment_accessorial|
      transponder_codes.exclude?(shipment_accessorial.accessorial.transponder_code)
    end
    kept_transponder_codes = kept.map { |shipment_accessorial| shipment_accessorial.accessorial.transponder_code }
    added = accessorials.reject { |accessorial| kept_transponder_codes.include?(accessorial.transponder_code) }

    [
      *removed.map { |shipment_accessorial| { _destroy: true, id: shipment_accessorial.id } },
      *added.map { |accessorial| { accessorial: } }
    ]
  end

  def unsupported_codes = codes.reject { |code| accessorials.map(&:transponder_code).include?(EBOL.transponder_code(code)) }

  private

  def mapped_shipment_accessorials
    shipment.shipment_accessorials.includes(:accessorial).where(accessorial: { transponder_code: EBOL::ACCESSORIAL_CODES.keys })
  end
end
