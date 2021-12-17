# frozen_string_literal: true

# == Schema Information
#
# Table name: addresses
#
# @!attribute id
#   @return []
# @!attribute city
#   @return [String]
# @!attribute google_places_spot_cached
#   @return [String]
# @!attribute google_places_spot_updated_at
#   @return [Time]
# @!attribute latitude
#   @return []
# @!attribute longitude
#   @return []
# @!attribute open_street_map_result_cached
#   @return [String]
# @!attribute open_street_map_result_updated_at
#   @return [Time]
# @!attribute original_attributes
#   @return [String]
# @!attribute ref
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute state
#   @return [String]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute time_zone
#   @return [String]
# @!attribute types
#   @return [String]
# @!attribute verification_info
#   @return [String]
# @!attribute zip_code
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return [Integer]
# @!attribute region_id
#   @return []
#
# Indexes
#
#  index_addresses_on_country_id  (country_id)
#  index_addresses_on_region_id   (region_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (region_id => regions.id)
#
class Address < ApplicationRecord
  # before_save :prettify_city, if: :city_changed?
  # before_save :prettify_state, if: :state_changed?

  # before_save :standardize_address
  # before_save :set_coordinates
  # before_save :set_time_zone
  # before_save :update_types

  before_validation :set_country

  belongs_to :country
  belongs_to :region

  serialize :google_places_spot_cached
  serialize :open_street_map_result_cached
  serialize :original_attributes
  serialize :time_zone
  serialize :types
  serialize :verification_info

  validate :region_matches_country

  # Temporarily disabled, see https://github.com/ankane/mainstreet/issues/14
  # validates_address fields: [:street, :city, :state, :zip_code], geocode: true

  validates :city, presence: true
  validates :zip_code, presence: true

  def pretty(seperator)
    str = ''.dup
    str << "#{ref}#{seperator}" unless ref.blank?
    str << "#{street}#{seperator}" unless street.blank?
    str << "#{street2}#{seperator}" unless street2.blank?
    str << "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')
    str
  end

  def proper(seperator)
    str = ''.dup
    str << "#{street}#{seperator}" unless street.blank?
    str << "#{street2}#{seperator}" unless street2.blank?
    str << "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')
    str
  end

  def locality
    "#{city}, #{region.abbreviation}".sub(',  ', '')
  end

  def permanently_closed?
    @permanently_closed ||= google_places_spot.permanently_closed
  end

  def commercial?
    return nil unless types

    types.include? 'commercial'
  end

  def residential?
    return nil unless types

    types.include? 'residential'
  end

  def restaurant?
    return nil unless types

    !(types & ['food', 'meal takeaway', 'restaurant']).empty?
  end

  def full_address?
    !street.blank? and !city.blank? and !region.blank?
  end

  def blank_to_nil(obj)
    obj == '' ? nil : obj
  end

  def names
    @names ||= (
      Shipment.where(shipper_address: self).pluck(:shipper_name) +
      Shipment.where(receiver_address: self).pluck(:receiver_name)
    ).uniq.reject { |name| name.blank? }
  end

  def twin
    addresses = Address.where(
      street: blank_to_nil(street),
      street2: blank_to_nil(street2),
      city: blank_to_nil(city),
      zip_code: blank_to_nil(zip_code)
    ).where.not(id: id).where('updated_at > ?', 6.months.ago).order(updated_at: :desc).limit(1)
    @twin = addresses&.first
  end

  def google_places_spot
    if @google_places_spot && !(will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?)
      return @google_places_spot
    end

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?
      self.google_places_spot_cached = nil
      self.google_places_spot_updated_at = nil
    end

    return @google_places_spot_cached = google_places_spot_cached unless google_places_spot_updated_at.blank?

    if twin&.google_places_spot_cached
      self.google_places_spot_cached = twin.google_places_spot_cached
    else
      logger.info 'Calling Google Places API'
      self.google_places_spot_cached = GooglePlaces::Client.new(
        ENV['GOOGLE_API_KEY']
      ).spots_by_query(
        (names&.first.blank? ? proper(', ') : "#{names&.first}, #{proper(', ')}")
      ).first
    end

    self.google_places_spot_updated_at = DateTime.current
    @google_places_spot = google_places_spot_cached
  end

  def open_street_map_result
    if @open_street_map_result && !(will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?)
      return @open_street_map_result
    end

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?
      self.open_street_map_result_updated_at = nil
    end

    unless open_street_map_result_updated_at.blank?
      return @open_street_map_result_cached = open_street_map_result_cached
    end

    if twin&.open_street_map_result_cached
      self.open_street_map_result_cached = twin.open_street_map_result_cached
    else
      logger.info 'Calling OpenStreetMap API'

      client = OpenStreetMap::Client.new

      self.open_street_map_result_cached = client.search(
        q: "#{street}, #{city}, #{region.abbreviation}, #{country.name}",
        format: 'json',
        addressdetails: '1',
        accept_language: 'en'
      )&.first
    end

    self.open_street_map_result_updated_at = DateTime.current
    @open_street_map_result = open_street_map_result_cached
  end

  def smarty_streets_result
    if @smarty_streets_result && !(will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?)
      return @smarty_streets_result
    end

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?
      self.smarty_streets_result_updated_at = nil
    end

    return @smarty_streets_result = verification_info unless smarty_streets_result_updated_at.blank?

    if twin&.verification_info
      self.verification_info = twin.verification_info
    else
      logger.info 'Calling SmartyStreet API'
      #      begin
      self.verification_info = MainStreet::AddressVerifier.new(proper(', ')).result # .data.to_hash
      #      rescue StandardError
      #        self.verification_info = nil
      #      end
    end

    self.smarty_streets_result_updated_at = DateTime.current
    @smarty_streets_result = verification_info
  end

  def standardize_address
    return self if smarty_streets_result.blank?

    self.original_attributes = attributes.slice(:street, :street2, :city, :state, :zip_code)

    if smarty_streets_result.dig('delivery_line_1')
      self.street = smarty_streets_result.dig('delivery_line_1') || "#{street} #{street2}"
      self.street2 = nil
    elsif smarty_streets_result.dig('formatted_address')
      self.street = smarty_streets_result.dig('formatted_address').split(',').first
      self.street2 = nil
    elsif smarty_streets_result.dig('display_name')
      self.street = "#{smarty_streets_result['house_number']} #{smarty_streets_result['street']}"
      self.street2 = nil
    end

    self.city = smarty_streets_result.dig('components', 'city_name') || city
    self.state = smarty_streets_result.dig('components', 'state_abbreviation') || state
    self.zip_code = smarty_streets_result.dig('components', 'zipcode') || zip_code

    # TODO: Remove this
    self
  end

  def next_types
    next_types = []
    streets_formatted = "#{street || ''} #{street2 || ''}".downcase
    if %w[aero aircraft aviation avionic hangar].any? { |word| streets_formatted.include?(word) }
      next_types << 'airport'
    end

    yaml = YAML.load_file(File.join(Rails.root, 'config', 'postal_codes.yml'))
    military_postal_codes = yaml['MILITARY'].inject([]) { |arr, postal_code| arr << postal_code.to_s }
    military_postal_codes.each do |military_postal_code|
      if zip_code.start_with?(military_postal_code) || (zip_code == military_postal_code)
        next_types << 'military'
        break
      end
    end

    next_types
  end

  def to_interstellar_shipping_address
    Interstellar::Location.new(
      address1: street,
      country: country.alpha2_code,
      state: region.abbreviation,
      city: city,
      zip: zip_code
    )
  end

  def update_types
    return self unless full_address?

    types = []

    if twin.blank?
      types = google_places_spot.types unless google_places_spot.blank?
      unless smarty_streets_result.blank?
        types << smarty_streets_result.dig('metadata', 'rdi')
        types -= %w[street_address premise]
      end

      begin
        types = types.map(&:downcase).map { |t| t.gsub('_', ' ') }
      rescue StandardError
        types = []
      end

      types = types - ['subpremise'] + ['apartment'] if types.include? %w[residential subpremise]
      types -= %w[establishment premise]
    else
      types = twin.types
    end
    self.types = (next_types + types).sort.uniq
    self
  end

  def set_coordinates
    return self unless full_address?

    if !open_street_map_result.blank? && !open_street_map_result['lat'].blank? && !open_street_map_result['lon'].blank?
      self.latitude = open_street_map_result['lat']
      self.longitude = open_street_map_result['lon']
      return true
    end

    if !google_places_spot.blank? && !google_places_spot&.lat.blank? && !google_places_spot&.lng.blank?
      self.latitude = google_places_spot.lat
      self.longitude = google_places_spot.lng
      return true
    end

    false
  end

  def set_time_zone
    set_coordinates if latitude.blank? || longitude.blank?

    if latitude.blank? || longitude.blank?
      self.time_zone = Timezone['America/Los_Angeles']
      return
    end

    self.time_zone = Timezone.lookup(latitude, longitude)
  end

  private

  def set_country
    return if region.blank? || !country.blank?

    self.country = region.country
  end

  def region_matches_country
    return if region.blank? || country.blank?

    errors.add(:region, "isn't within #{country.name}") unless region.country == country
  end

  # Prettify
  def prettify_city
    self.city = city.titleize if (city == city.downcase) || (city == city.upcase)
  end

  def prettify_state
    self.state = state.upcase if state != state.upcase
  end
end
