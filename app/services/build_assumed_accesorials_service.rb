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

  def call
    transponder_codes = []

    [[:delivery, receiver_address_name], [:pickup, shipper_address_name]].each do |stop, name|
      transponder_codes << :"airport_#{stop}" if name.present? && ['airport', 'hangar'].any? { |word| name.downcase.include?(word) }
    end

    [[:delivery, receiver_address], [:pickup, shipper_address]].each do |stop, address|
      transponder_codes << :"airport_#{stop}" if address.types.present? && (address.types.include? 'airport')
      transponder_codes << :"military_site_#{stop}" if address.types.present? && (address.types.include? 'military_site')
      transponder_codes.push(:"residential_#{stop}", :"appointment_#{stop}") if residential?(address, stop)
      transponder_codes << :"liftgate_#{stop}" if liftgate?(address, stop)
      transponder_codes << :"restaurant_#{stop}" if address.restaurant?
    end

    transponder_codes << :appointment_delivery if bol_notes.present? && (bol_notes.downcase.include? 'must contact')

    Accessorial.with_transponder_codes(transponder_codes.uniq, broker_customer: shipment.broker_customer)
  end

  private

  def heavy? = items.any? { |item| item.weight.to_f >= 200 }
  def liftgate?(address, stop) = (residential?(address, stop) || no_dock?(address)) && heavy?
  def no_dock?(address) = address.dock.nil? ? address.restaurant? || address.types.intersect?(NO_DOCK_TYPES) : !address.dock

  def residential?(address, stop)
    address.residential? || shipment.selected_accessorials.map(&:transponder_code).include?("residential_#{stop}")
  end
end
