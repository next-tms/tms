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
# @!attribute standardized_address_id
#   @return []
#
# Indexes
#
#  index_addresses_on_country_id               (country_id)
#  index_addresses_on_region_id                (region_id)
#  index_addresses_on_standardized_address_id  (standardized_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (region_id => regions.id)
#  fk_rails_...  (standardized_address_id => standardized_addresses.id)
#
class Address < ApplicationRecord
  before_save :sanitize_city
  before_save :sanitize_street
  before_save :set_standardized_address, unless: -> { Rails.env.test? }

  before_validation :set_country

  belongs_to :country
  belongs_to :region
  belongs_to :standardized_address, counter_cache: true, optional: true

  serialize :types

  validate :region_matches_country

  validates :city, presence: true
  validates :zip_code, presence: true

  def pretty(seperator)
    str = ''.dup
    str << "#{ref}#{seperator}" if ref.present?
    str << "#{street}#{seperator}" if street.present?
    str << "#{street2}#{seperator}" if street2.present?
    str << "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')
    str
  end

  def proper(seperator)
    str = ''.dup
    str << "#{street}#{seperator}" if street.present?
    str << "#{street2}#{seperator}" if street2.present?
    str << "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')
    str
  end

  def locality
    "#{city}, #{region.abbreviation}".sub(',  ', '')
  end

  def permanently_closed?
    standardized_address&.permanently_closed?
  end

  def commercial?
    standardized_address&.commercial?
  end

  def residential?
    standardized_address&.residential?
  end

  def restaurant?
    standardized_address&.restaurant?
  end

  def full_address?
    street.present? && city.present? && region.present?
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

  def time_zone
    return standardized_address.time_zone if standardized_address.present?
    return ActiveSupport::TimeZone.new('America/Los_Angeles') if time_zone_name.blank?

    ActiveSupport::TimeZone.new(time_zone_name)
  end

  def types
    standardized_address&.types || []
  end

  def to_interstellar_shipping_address
    Interstellar::Location.new(
      address1: street,
      city:,
      country: ActiveUtils::Country.find(country.alpha2_code),
      postal_code: zip_code,
      province: region.abbreviation,
    )
  end

  def find_or_build_standardized_address
    return unless full_address?

    key = region.country.format_address(proper(', '))
    key = proper(', ') if key.blank?

    new_standardized_address = StandardizedAddress.where(country: region.country, key:)&.first

    new_standardized_address ||= StandardizedAddress.new(
      street:,
      street2:,
      city:,
      region_id:,
      postal_code: zip_code,
      country_id:,
      key:,
    )

    self.standardized_address = new_standardized_address
  end

  def set_standardized_address
    return unless full_address?

    find_or_build_standardized_address
    standardized_address.save

    return unless standardized_address.persisted?

    self.street = standardized_address.street || street
    self.street2 = standardized_address.street2 || street2
    self.city = standardized_address.city || city
    self.region = standardized_address.region || region
    self.zip_code = standardized_address.postal_code || zip_code
  end

  def to_quickbooks_physical_address
    Quickbooks::Model::PhysicalAddress.new(
      line1: street,
      line2: street2,
      city:,
      country_sub_division_code: region.abbreviation,
      postal_code: zip_code,
    )
  end

  private

  def sanitize_city
    new_city = city

    new_city = new_city.titleize if (new_city == new_city.downcase) || (new_city == new_city.upcase)

    until new_city.strip.last != ','
      new_city.strip!
      new_city = new_city[..-2]
    end

    new_city.strip!

    self.city = new_city
  end

  def sanitize_street
    return if street.blank?

    new_street = street
    new_street = new_street.titleize if (new_street == new_street.downcase) || (new_street == new_street.upcase)

    until new_street.strip.last != ','
      new_street.strip!
      new_street = new_street[..-2]
    end

    new_street.strip!

    self.street = new_street
  end

  def set_country
    return if region.blank? || country.present?

    self.country = region.country
  end

  def region_matches_country
    return if region.blank? || country.blank?

    errors.add(:region, "isn't within #{country.name}") unless region.country == country
  end
end
