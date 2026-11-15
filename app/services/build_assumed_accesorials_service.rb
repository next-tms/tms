class BuildAssumedAccesorialsService
  delegate(*%i[receiver_address receiver_address_name shipper_address shipper_address_name items bol_notes], to: :shipment)

  attr_reader :shipment

  NO_DOCK_TYPES = [
    'amusement_park',
    'athletic_facility',
    'cemetery',
    'church',
    'farm',
    'fitness_center',
    'golf_course',
    'hospital',
    'hotel',
    'mall',
    'motel',
    'nursing_home',
    'park',
    'resort',
    'restaurant',
    'school',
    'university'
  ].freeze

  def initialize(shipment:)
    @shipment = shipment
  end

  # Collect Shipment Accessorials base from shipper and receiver details
  # Codes for both shipper and receiver details are the same but will differ in the
  # Prefix e.g PAIR for Shipper (P = Pickup) and DAIR for Receiver (D = Delivery)
  def call
    accessorials = []
    [['D', receiver_address_name], ['P', shipper_address_name]].each do |prefix, name|
      if name.present? && ['airport', 'hangar'].any? { |word| name.downcase.include?(word) }
        accessorials << Accessorial.find_by(code: "#{prefix}AIR") # Airports
      end
    end

    [['D', receiver_address], ['P', shipper_address]].each do |prefix, address|
      # Airports
      accessorials << Accessorial.find_by(code: "#{prefix}AIR") if address.types.present? && (address.types.include? 'airport')
      # Military bases
      accessorials << Accessorial.find_by(code: "#{prefix}MIL") if address.types.present? && (address.types.include? 'military_site')

      # Residential
      if residential?(address, prefix)
        accessorials << Accessorial.find_by(code: "#{prefix}RES")
        accessorials << Accessorial.find_by(code: "#{prefix}APP")
      end

      accessorials << Accessorial.find_by(code: "#{prefix}LIF") if liftgate?(address, prefix)

      # Restaurant
      accessorials << Accessorial.find_by(code: "#{prefix}RST") if address.restaurant?
    end

    # Appointment delivery
    accessorials << Accessorial.find_by(code: 'DAPP') if bol_notes.present? && (bol_notes.downcase.include? 'must contact')

    accessorials.compact.uniq
  end

  private

  def heavy? = items.any? { |item| item.weight.to_f >= 200 }
  def liftgate?(address, prefix) = (residential?(address, prefix) || no_dock?(address)) && heavy?
  def no_dock?(address) = address.dock.nil? ? address.restaurant? || address.types.intersect?(NO_DOCK_TYPES) : !address.dock
  def residential?(address, prefix) = address.residential? || shipment.accessorial_codes.include?("#{prefix}RES")
end
