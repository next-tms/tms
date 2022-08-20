# frozen_string_literal: true

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
# @!attribute smarty_streets_result_cached
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return []
# @!attribute region_id
#   @return []
#
# Indexes
#
#  index_standardized_addresses_on_country_id  (country_id)
#  index_standardized_addresses_on_key         (key)
#  index_standardized_addresses_on_region_id   (region_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (region_id => regions.id)
#
class StandardizedAddress < ApplicationRecord
  before_validation :standardize_address
  before_validation :set_coordinates
  before_validation :set_time_zone_name

  belongs_to :country
  belongs_to :region

  has_many :addresses, dependent: :nullify

  serialize :google_places_spot_cached
  serialize :open_street_map_result_cached
  serialize :original_attributes
  serialize :smarty_streets_result_cached

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

  def blank_to_nil(obj)
    obj == '' ? nil : obj
  end

  def names
    @names ||= (
      Shipment.where(shipper_address: self).pluck(:shipper_name) +
      Shipment.where(receiver_address: self).pluck(:receiver_name)
    ).uniq.reject(&:blank?)
  end

  def google_places_spot
    return @google_places_spot if @google_places_spot

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_postal_code?
      self.google_places_spot_cached = nil
      self.google_places_spot_updated_at = nil
    end

    if !google_places_spot_updated_at.blank? && google_places_spot_updated_at > 3.months.ago
      return @google_places_spot_cached = google_places_spot_cached
    end

    logger.info 'Calling Google Places API'

    result = GooglePlaces::Client
             .new(Rails.application.credentials.google.api_key)
             .spots_by_query((names&.first.blank? ? key : "#{names&.first}, #{key}"))
             &.first

    accurate = result.is_a?(GooglePlaces::Spot) &&
               street.scan(/\d+/).map { |d| result.formatted_address.include?(d) }.all?(true)

    self.google_places_spot_cached = accurate ? result : nil
    self.google_places_spot_updated_at = DateTime.current

    @google_places_spot = google_places_spot_cached
  end

  def open_street_map_result
    return @open_street_map_result if @open_street_map_result

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_postal_code?
      self.open_street_map_result_updated_at = nil
    end

    if !open_street_map_result_updated_at.blank? && open_street_map_result_updated_at > 3.months.ago
      return @open_street_map_result_cached = open_street_map_result_cached
    end

    logger.info 'Calling OpenStreetMap API'

    client = OpenStreetMap::Client.new
    result = client.search(
      q: "#{key}, #{country.name}",
      format: 'json',
      addressdetails: '1',
      accept_language: 'en'
    )&.first

    accurate = result.is_a?(Hash) &&
               street.scan(/\d+/).map { |d| result['display_name'].include?(d) }.all?(true)

    self.open_street_map_result_cached = accurate ? result : nil
    self.open_street_map_result_updated_at = DateTime.current

    @open_street_map_result = open_street_map_result_cached
  end

  def smarty_streets_result
    return @smarty_streets_result if @smarty_streets_result

    google_places_spot
    open_street_map_result

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_postal_code?
      self.smarty_streets_result_updated_at = nil
    end

    if !smarty_streets_result_updated_at.blank? && smarty_streets_result_updated_at > 3.months.ago
      return @smarty_streets_result = smarty_streets_result_cached
    end

    logger.info 'Calling SmartyStreet API'
    self.smarty_streets_result_cached = MainStreet::AddressVerifier.new(key).result&.data&.to_hash

    self.smarty_streets_result_updated_at = DateTime.current
    @smarty_streets_result = smarty_streets_result_cached
  end

  def standardize_address
    return if smarty_streets_result.blank?

    if smarty_streets_result['delivery_line_1'].present?
      self.street = smarty_streets_result['delivery_line_1']
      self.street2 = nil
    elsif smarty_streets_result['formatted_address'].present?
      self.street = smarty_streets_result['formatted_address'].split(',').first
      self.street2 = nil
    elsif smarty_streets_result['house_number'].present? && smarty_streets_result['street'].present?
      self.street = "#{smarty_streets_result['house_number']} #{smarty_streets_result['street']}"
      self.street2 = nil
    end

    self.city = smarty_streets_result.dig('components', 'city_name') || city
    self.region = Region.where(abbreviation: smarty_streets_result.dig('components',
                                                                       'state_abbreviation'))&.first || region
    self.postal_code = smarty_streets_result.dig('components', 'zipcode') || postal_code
  end

  def next_types
    next_types = []
    streets_formatted = "#{street || ''} #{street2 || ''}".downcase

    # Removed "aero", "aviation" as they can lead to incorrect type
    next_types << 'airport' if %w[aircraft avionic hangar].any? { |word| streets_formatted.include?(word) }

    yaml = YAML.load_file(File.join(Rails.root, 'config', 'postal_codes.yml'))
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

    (next_types + types).sort.uniq
  end

  def set_coordinates
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

  def time_zone
    ActiveSupport::TimeZone.new(time_zone_name.blank? ? 'America/Los_Angeles' : time_zone_name)
  end

  # private

  def set_country
    return if region.blank? || !country.blank?

    self.country = region.country
  end

  def region_matches_country
    return if region.blank? || country.blank?

    errors.add(:region, "isn't within #{country.name}") unless region.country == country
  end

  def set_time_zone_name
    set_coordinates if latitude.blank? || longitude.blank?

    if latitude.blank? || longitude.blank?
      self.time_zone_name = 'America/Los_Angeles'
      return
    end

    begin
      self.time_zone_name = Timezone.lookup(latitude, longitude)&.name || 'America/Los_Angeles'
    rescue Timezone::Error::GeoNames
      self.time_zone_name = 'America/Los_Angeles'
    end
  end
end
