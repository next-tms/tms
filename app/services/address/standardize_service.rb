class Address::StandardizeService
  attr_reader :address

  def initialize(address:)
    @address = address
  end

  def call
    clear_location if address.moved?
    return unless address.full_address?

    verification = Geo.verify(**address.to_postal_address)
    return if verification.nil?

    assign_place(place(verification))
    return if renamed?

    assign_verification(verification)
    assign_time_zone
  end

  private

  def assign_place(place)
    address.permanently_closed = place&.permanently_closed
    address.types = Array(place&.types)
  end

  def assign_time_zone
    return if address.latitude.blank? || address.longitude.blank?

    address.time_zone_name = Geo.time_zone(latitude: address.latitude, longitude: address.longitude) || address.time_zone_name
  end

  def assign_verification(verification)
    street, street2 = verification.address_lines

    address.business = verification.business
    address.city = verification.locality.presence || address.city
    address.dock = verification.dock
    address.fingerprint = verification.fingerprint
    address.latitude = verification.latitude || address.latitude
    address.longitude = verification.longitude || address.longitude
    address.place_id = verification.place_id
    address.po_box = verification.po_box
    address.region = region(verification.administrative_area) || address.region
    address.residential = verification.residential
    address.street = street.presence || address.street
    address.street2 = street2.presence if street.present?
    address.zip_code = verification.postal_code.presence || address.zip_code
  end

  def clear_location
    address.assign_attributes(
      business: nil,
      dock: nil,
      fingerprint: nil,
      latitude: nil,
      longitude: nil,
      permanently_closed: nil,
      place_id: nil,
      po_box: nil,
      residential: nil,
      time_zone_name: nil,
      types: []
    )
  end

  def named?(place) = address.name.present? && normalized(place.name) == normalized(address.name)
  def normalized(name) = name.to_s.downcase.gsub(/[^[:alnum:]]/, '')

  def place(verification)
    return verification.places.find { named?(it) } unless verification.places.nil?

    Geo.place(verification.place_id, provider: verification.place_provider) if verification.place_id.present?
  end

  def renamed? = address.persisted? && !address.moved?
  def region(abbreviation) = abbreviation.present? && address.country&.regions&.find_by(abbreviation:)
end
