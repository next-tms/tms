# frozen_string_literal: true

class Address < ApplicationRecord
  # TODO: Remove this - where did this come from?
  # has_many :shipments, class_name: 'Sale', foreign_key: 'shipment_id'

  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true

  # Prettify
  before_save :prettify_city, if: :city_changed?
  before_save :prettify_state, if: :state_changed?

  def pretty(seperator)
    str = ''.dup
    str << "#{ref}#{seperator}" unless ref.blank?
    str << "#{street}#{seperator}" unless street.blank?
    str << "#{street2}#{seperator}" unless street2.blank?
    str << "#{city}, #{state} #{zip_code}".sub(',  ', '')
    str
  end

  def proper(seperator)
    str = ''.dup
    str << "#{street}#{seperator}" unless street.blank?
    str << "#{street2}#{seperator}" unless street2.blank?
    str << "#{city}, #{state} #{zip_code}".sub(',  ', '')
    str
  end

  def locality
    "#{city}, #{state}".sub(',  ', '')
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

  def full_address?
    !street.blank? and !city.blank? and !state.blank?
  end

  # Temporarily disabled, see https://github.com/ankane/mainstreet/issues/14
  # validates_address fields: [:street, :city, :state, :zip_code], geocode: true

  serialize :google_places_spot_cached
  serialize :original_attributes
  serialize :time_zone
  serialize :types
  serialize :verification_info

  before_save :standardize_address
  before_save :update_coordinates
  before_save :update_types
  before_save :update_time_zone

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
    addresses = Address.where(street: blank_to_nil(street), street2: blank_to_nil(street2), city: blank_to_nil(city), zip_code: blank_to_nil(zip_code)).where('updated_at > ?', 6.months.ago).order(updated_at: :desc).limit(1)
    @twin = addresses.first unless addresses.blank?
  end

  def smarty_streets_result
    if @smarty_streets_result && !(will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?)
      return @smarty_streets_result
    end

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?
      self.verification_info = nil
    end

    unless verification_info
      if twin&.verification_info
        self.verification_info = twin.verification_info
      else
        logger.info 'Calling SmartyStreet API'
        begin
          self.verification_info = MainStreet::AddressVerifier.new(proper(', ')).result.data.to_hash
        rescue StandardError
          self.verification_info = nil
        end
      end
    end
    @smarty_streets_result = verification_info
  end

  def google_places_spot
    if @google_places_spot && !(will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?)
      return @google_places_spot
    end

    if will_save_change_to_street? || will_save_change_to_city? || will_save_change_to_zip_code?
      self.google_places_spot_cached = nil
    end

    unless google_places_spot_cached
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
    end
    @google_places_spot = google_places_spot_cached
  end

  def standardize_address
    if full_address? && !smarty_streets_result.blank?
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
    end
    self
  end

  def liftoff_types
    liftoff_types = []
    streets_formatted = "#{street || ''} #{street2 || ''}".downcase
    if %w[aero aircraft aviation avionic hangar].any? { |word| streets_formatted.include?(word) }
      liftoff_types << 'airport'
    end

    yaml = YAML.load_file(File.join(Rails.root, 'config', 'postal_codes.yml'))
    military_postal_codes = yaml['MILITARY'].inject([]) { |arr, postal_code| arr << postal_code.to_s }
    military_postal_codes.each do |military_postal_code|
      if zip_code.start_with?(military_postal_code) || (zip_code == military_postal_code)
        liftoff_types << 'military'
        break
      end
    end

    liftoff_types
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
    self.types = (liftoff_types + types).sort.uniq
    self
  end

  def update_coordinates
    return self unless full_address?

    # Google more accurate than SmartyStreets
    unless google_places_spot.blank?
      self.latitude = google_places_spot.lat
      self.longitude = google_places_spot.lng
    end
    self
  end

  def update_time_zone
    self.time_zone = if google_places_spot
                       Timezone.lookup(google_places_spot.lat, google_places_spot.lng)
                     else
                       Timezone['America/Los_Angeles']
                     end
    self
  end

  private

  # Prettify
  def prettify_city
    self.city = city.titleize if (city == city.downcase) || (city == city.upcase)
  end

  def prettify_state
    self.state = state.upcase if state != state.upcase
  end
end
