class BuildAssumedAccesorialsService
  delegate(*%i[
             receiver_address
             receiver_name
             shipper_address
             shipper_name
             items
             bol_notes
           ], to: :shipment)

  attr_reader :shipment

  def initialize(shipment:)
    @shipment = shipment
  end

  # Collect Shipment Accessorials base from shipper and receiver details
  # Codes for both shipper and receiver details are the same but will differ in the
  # Prefix e.g PAIR for Shipper (P = Pickup) and DAIR for Receiver (D = Delivery)
  def call
    accessorials = []
    [['D', receiver_name], ['P', shipper_name]].each do |prefix, name|
      if name.present? && ['airport', 'hangar'].any? { |word| name.downcase.include?(word) }
        accessorials << Accessorial.find_by(code: "#{prefix}AIR") # Airports
      end
    end

    [['D', receiver_address], ['P', shipper_address]].each do |prefix, address|
      # Airports
      accessorials << Accessorial.find_by(code: "#{prefix}AIR") if address.types.present? && (address.types.include? 'airport')
      # Military bases
      accessorials << Accessorial.find_by(code: "#{prefix}MIL") if address.types.present? && (address.types.include? 'military')

      # Residential
      if address.residential? || shipment.accessorial_codes.include?("#{prefix}RES")
        accessorials << Accessorial.find_by(code: "#{prefix}RES")
        accessorials << Accessorial.find_by(code: "#{prefix}APP")
        if items.order(Arel.sql('items.weight / items.quantity DESC')).limit(1).first.weight >= 200
          accessorials << Accessorial.find_by(code: "#{prefix}LIF")
        end
      end

      # Restaurant
      accessorials << Accessorial.find_by(code: "#{prefix}RST") if address.restaurant?
    end

    # Appointment delivery
    accessorials << Accessorial.find_by(code: 'DAPP') if bol_notes.present? && (bol_notes.downcase.include? 'must contact')

    accessorials.uniq
  end
end
