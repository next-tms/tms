class Freightview::LTLShipmentPayload
  HAZARDOUS = %i[
    hazmatId
    limitedQuantity
    marinePollutant
    packingGroup
    permitNumber
    primaryClass
    properShippingName
    reportableQuantity
    residueLastContained
    secondaryClass
    technicalName
    tertiaryClass
  ].freeze
  COMMODITY = [
    :description,
    :freightClass,
    :isHazardous,
    :nmfcNumber,
    :nmfcSubNumber,
    :quantity,
    :type,
    :weight,
    { hazardous: HAZARDOUS }
  ].freeze
  CONTACT = %i[address address2 city country email phone phoneExt postalCode state].freeze
  HOURS_FORMAT = '%-l:%M %p'.freeze
  ITEM = [
    :description,
    :dimensionsUOM,
    :freightClass,
    :height,
    :isHazardous,
    :length,
    :nmfcNumber,
    :nmfcSubNumber,
    :quantity,
    :stackable,
    :type,
    :weight,
    :weightUOM,
    :width,
    { contains: [COMMODITY], hazardous: HAZARDOUS }
  ].freeze
  LOCATION = [
    :address,
    :address2,
    :city,
    :closesAt,
    :company,
    :contactEmail,
    :contactName,
    :contactPhone,
    :contactPhoneExt,
    :country,
    :instructions,
    :opensAt,
    :postalCode,
    :shipType,
    :state,
    { accessorials: %i[inside liftgate notify schedule sortAndSegregate], refNums: [%i[type value]] }
  ].freeze
  PERMITTED = [
    :bolNumber,
    :glCode,
    :pickupDate,
    {
      billTo: %i[address address2 city company contactEmail contactName contactPhone contactPhoneExt country postalCode state],
      customsBrokers: [[*CONTACT, :companyName, :type, :value]],
      destination: LOCATION,
      emergencyContact: %i[contractNumber name phone phoneExt],
      equipment: [{ accessorials: %i[protect-from-freezing single-shipment], alternateTypes: [] }],
      items: [ITEM],
      origin: LOCATION,
      shareShipmentEmails: []
    }
  ].freeze
  ROOT_KEYS = PERMITTED.flat_map { |key| key.is_a?(Hash) ? key.keys : key }.map(&:to_s).sort.freeze

  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def accessorial_codes = Freightview::STOPS.keys.flat_map { |stop| stop_accessorial_codes(stop) }

  def shipment_attributes
    {
      bol: attributes[:bol_number],
      items_attributes: attributes.fetch(:items, []).map { |item| item_attributes(item) },
      pickup_on: Date.iso8601(required(attributes, :pickup_date)),
      **stop_attributes(:destination),
      **stop_attributes(:origin)
    }
  end

  def unsupported_accessorials
    Freightview::STOPS.keys.flat_map do |stop|
      selected_accessorials(stop).excluding(*Freightview::ACCESSORIALS[stop].keys).map { |name| [stop, :accessorials, name] }
    end
  end

  private

  def address_attributes(location)
    country = required(location, :country).upcase

    {
      city: location[:city],
      country_alpha2: country,
      name: location[:company],
      region_iso31662: location[:state].presence&.then { |state| "#{country}-#{state.upcase}" },
      street: location[:address],
      street2: location[:address2],
      zip_code: required(location, :postal_code)
    }.compact
  end

  def hours(value) = value.presence&.then { |time| Time.strptime(time, '%H:%M').strftime(HOURS_FORMAT) }

  def item_attributes(item)
    {
      declared_freight_class: item[:freight_class],
      desc: item[:description].presence || 'Freight',
      h: item[:height],
      hazmat: ActiveModel::Type::Boolean.new.cast(item[:is_hazardous]) || false,
      l: item[:length],
      nmfc: [item[:nmfc_number], item[:nmfc_sub_number]].compact_blank.join('-').presence,
      packaging: Packaging.find_by(freight_kit_type: item[:type]) || Packaging.find_by(freight_kit_type: :piece),
      quantity: item[:quantity],
      w: item[:width],
      weight: item[:weight]
    }
  end

  def required(hash, key) = hash[key].presence || raise(ActionController::ParameterMissing, key)

  def selected_accessorials(stop)
    accessorials = attributes.dig(stop, :accessorials) || {}

    accessorials.keys.select { |name| ActiveModel::Type::Boolean.new.cast(accessorials[name]) }
  end

  def stop_accessorial_codes(stop)
    ship_type = Freightview.decode(attributes.dig(stop, :ship_type))
    codes = selected_accessorials(stop).filter_map { |name| Freightview::ACCESSORIALS[stop][name] }

    Freightview::SHIP_TYPES.include?(ship_type) ? [*codes, :"#{ship_type}_#{Freightview::STOPS[stop].last}"] : codes
  end

  def stop_attributes(stop)
    location = required(attributes, stop)
    prefix, window = Freightview::STOPS[stop]

    {
      "#{prefix}_address_attributes": address_attributes(location),
      "#{prefix}_contact_email": location[:contact_email],
      "#{prefix}_contact_name": location[:contact_name],
      "#{prefix}_contact_phone": [location[:contact_phone], location[:contact_phone_ext]].compact_blank.join(' x').presence,
      "#{window}_hours_end_at": hours(location[:closes_at]),
      "#{window}_hours_start_at": hours(location[:opens_at])
    }.compact
  end
end
