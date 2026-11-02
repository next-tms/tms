# == Schema Information
#
# Table name: standardized_addresses
#
# @!attribute id
#   @return []
# @!attribute addresses_count
#   @return [Integer]
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute google_places_spot_cached
#   @return [String]
# @!attribute google_places_spot_updated_at
#   @return [Time]
# @!attribute key
#   @return [String]
# @!attribute latitude
#   @return [String]
# @!attribute longitude
#   @return [String]
# @!attribute open_street_map_result_cached
#   @return [String]
# @!attribute open_street_map_result_updated_at
#   @return [Time]
# @!attribute postal_code
#   @return [String]
# @!attribute region_iso31662
#   @return [String]
# @!attribute smarty_streets_result_cached
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_standardized_addresses_on_country_alpha2   (country_alpha2)
#  index_standardized_addresses_on_key              (key)
#  index_standardized_addresses_on_region_iso31662  (region_iso31662)
#
class StandardizedAddress < ApplicationRecord
  attr_accessor :skip_smarty_streets_result_api_request, :skip_google_places_spot_api_request, :skip_open_street_map_result_api_request

  before_validation :standardize_address
  before_validation :set_coordinates
  before_validation :set_time_zone_name

  belongs_to_transponder :country, foreign_key: :country_alpha2
  belongs_to_transponder :region, foreign_key: :region_iso31662

  has_many :addresses, dependent: :nullify

  normalizes :city, :postal_code, :street, :street2, with: ->(value) { value.squish }

  serialize :google_places_spot_cached, coder: YAML
  serialize :open_street_map_result_cached, coder: YAML
  serialize :original_attributes, coder: YAML
  serialize :smarty_streets_result_cached, coder: YAML

  validate :region_matches_country

  validates :city, presence: true
  validates :google_places_spot_updated_at, presence: true
  validates :key, presence: true
  validates :open_street_map_result_updated_at, presence: true
  validates :postal_code, presence: true
  validates :smarty_streets_result_updated_at, presence: true
  validates :street, presence: true

  def permanently_closed?
    @permanently_closed ||= google_places_spot.permanently_closed
  end

  def commercial?
    types&.include?('commercial')
  end

  def residential?
    types&.include?('residential')
  end

  def restaurant?
    return false unless types

    !!types.intersect?(['food', 'meal takeaway', 'restaurant'])
  end

  def blank_to_nil(obj)
    obj == '' ? nil : obj
  end

  def names
    @names ||= (
      Shipment.where(shipper_address: self).pluck(:shipper_name) + Shipment.where(receiver_address: self).pluck(:receiver_name)
    ).uniq.compact_blank
  end

  def google_places_spot
    return if skip_google_places_spot_api_request
    return @google_places_spot if @google_places_spot
    return @google_places_spot_cached = google_places_spot_cached if up_to_date_cached_response?(:google_places_spot)

    address_key = names&.first.blank? ? key : "#{names.first}, #{key}"
    result = Address::GooglePlacesVerifyService.new(address_key:, street:).call

    update_api_response_cache_and_timestamp(:google_places_spot, result)
    @google_places_spot = result
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Sentry.capture_exception(e)

    nil
  end

  def open_street_map_result
    return if skip_open_street_map_result_api_request
    return @open_street_map_result if @open_street_map_result

    return @open_street_map_result = open_street_map_result_cached if up_to_date_cached_response?(:open_street_map_result)

    self.open_street_map_result_updated_at = Time.current
    @open_street_map_result = nil
  end

  def smarty_streets_result
    return if skip_smarty_streets_result_api_request
    return @smarty_streets_result if @smarty_streets_result
    return @smarty_streets_result = smarty_streets_result_cached if up_to_date_cached_response?(:smarty_streets_result)

    @smarty_streets_result = Address::SmartyStreetsVerifyService.new(address_key: key).call

    update_api_response_cache_and_timestamp(:smarty_streets_result, @smarty_streets_result)
    @smarty_streets_result
  end

  def fetch_third_party_geolocation_services_data
    smarty_streets_result unless skip_smarty_streets_result_api_request
    google_places_spot
    open_street_map_result
  end

  def standardize_address
    fetch_third_party_geolocation_services_data
    return if smarty_streets_result.blank?

    self.street2 = nil

    if smarty_streets_result['delivery_line_1'].present?
      self.street = smarty_streets_result['delivery_line_1']
    elsif smarty_streets_result['formatted_address'].present?
      self.street = smarty_streets_result['formatted_address'].split(',').first
    elsif smarty_streets_result['house_number'].present? && smarty_streets_result['street'].present?
      self.street = "#{smarty_streets_result['house_number']} #{smarty_streets_result['street']}"
    end

    self.city = smarty_streets_result.dig('components', 'city_name') || city
    self.region = Transponder::ORM::Region.find_by(
      abbreviation: smarty_streets_result.dig('components', 'state_abbreviation'),
      country:
    ) || region
    self.postal_code = smarty_streets_result.dig('components', 'zipcode') || postal_code
  end

  def next_types
    next_types = []
    streets_formatted = "#{street || ''} #{street2 || ''}".downcase

    # Removed "aero", "aviation" as they can lead to incorrect type
    next_types << 'airport' if ['aircraft', 'avionic', 'hangar'].any? { |word| streets_formatted.include?(word) }

    yaml = YAML.load_file(Rails.root.join('config/postal_codes.yml').to_s)
    military_postal_codes = yaml['MILITARY'].inject([]) { |arr, postal_code| arr << postal_code.to_s }
    military_postal_codes.each do |military_postal_code|
      if postal_code.start_with?(military_postal_code) || (postal_code == military_postal_code)
        next_types << 'military'
        break
      end
    end

    next_types
  end

  def types
    types = []

    types = google_places_spot.types if google_places_spot.present?
    if smarty_streets_result.present?
      types << smarty_streets_result.dig('metadata', 'rdi')
      types -= ['street_address', 'premise']
    end

    begin
      types = types.map(&:downcase).map { |t| t.gsub('_', ' ') }
    rescue StandardError
      types = []
    end

    types = types - ['subpremise'] + ['apartment'] if types.include?(['residential', 'subpremise'])
    types -= ['establishment', 'premise']

    (next_types + types).sort.uniq
  end

  def set_coordinates
    if open_street_map_result.present? &&
       open_street_map_result['lat'].present? &&
       open_street_map_result['lon'].present?
      self.latitude = open_street_map_result['lat']
      self.longitude = open_street_map_result['lon']
      return
    end

    return unless google_places_spot.present? && google_places_spot&.lat.present? && google_places_spot&.lng.present?

    self.latitude = google_places_spot.lat
    self.longitude = google_places_spot.lng
  end

  def time_zone
    ActiveSupport::TimeZone.new(time_zone_name.presence || 'America/Los_Angeles')
  end

  # private

  def set_country
    return if region.blank? || country.present?

    self.country = region.country
  end

  def region_matches_country
    return if region.blank? || country.blank?

    errors.add(:region, "isn't within #{country.name}") unless region.country == country
  end

  def set_time_zone_name
    set_coordinates if latitude.blank? || longitude.blank?
    return self.time_zone_name = 'America/Los_Angeles' if latitude.blank? || longitude.blank?

    self.time_zone_name = Timezone.lookup(latitude, longitude)&.name || 'America/Los_Angeles'
  rescue Timezone::Error::GeoNames
    self.time_zone_name = 'America/Los_Angeles'
  end

  private

  def up_to_date_cached_response?(type)
    cache_key = "#{type}_cached"
    updated_at_key = "#{type}_updated_at"

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_postal_code?
      public_send("#{cache_key}=", nil)
      public_send("#{updated_at_key}=", nil)
    end

    updated_at_timestamp = public_send(updated_at_key)

    updated_at_timestamp.present? && updated_at_timestamp > 3.months.ago
  end

  def update_api_response_cache_and_timestamp(type, response)
    cache_key = "#{type}_cached"
    updated_at_key = "#{type}_updated_at"
    skip_api_request_key = "skip_#{type}_api_request"

    # Prevent calling the API multiple times during Shipment Creation. Before a shipment is created standardized address
    # is called multiple times for address checking specifically on Suggesting Broker Accessorials. On Shipment creation
    # previously the Geolocation APIs are called atleast 8 times
    public_send("#{skip_api_request_key}=", true) if response.blank? && new_record?

    # Update table columns to ensure we only call the API every 3 months if its already cached,
    # use #update_columns so it would just directly update the DB and not run any active record callbacks
    if persisted?
      update_columns(cache_key => response, updated_at_key => Time.current) # rubocop:disable Rails/SkipsModelValidations
    else
      public_send("#{cache_key}=", response)
      public_send("#{updated_at_key}=", Time.current)
    end
  end
end
