class Address < ApplicationRecord
  AIRPORT_WORDS = ['aircraft', 'avionic', 'hangar'].freeze
  MILITARY_POSTAL_CODES = YAML.load_file(Rails.root.join('config/postal_codes.yml')).fetch('MILITARY').map(&:to_s).freeze
  POSTAL_ATTRIBUTES = ['city', 'country_alpha2', 'region_iso31662', 'street', 'street2', 'zip_code'].freeze

  audited associated_with: :shipment, on: :update, only: [*POSTAL_ATTRIBUTES, 'name', 'ref']

  before_save :standardize

  before_validation :set_country

  belongs_to_orm :country, class_name: 'Grid::ORM::Country', foreign_key: :country_alpha2
  belongs_to_orm :region, class_name: 'Grid::ORM::Region', foreign_key: :region_iso31662

  has_one :receiver_shipment, class_name: 'Shipment', dependent: nil, foreign_key: :receiver_address_id, inverse_of: :receiver_address
  has_one :shipper_shipment, class_name: 'Shipment', dependent: nil, foreign_key: :shipper_address_id, inverse_of: :shipper_address

  normalizes :city, with: ->(city) do
    new_city = city
    new_city = new_city.split(',')[0] if new_city.include?(',')
    new_city = city.titleize if (new_city == new_city.downcase) || (new_city == new_city.upcase)
    new_city.squish
  end
  normalizes :name, with: ->(name) { name.squish }
  normalizes :ref, with: ->(ref) { ref.squish }
  normalizes :street, with: ->(street) do
    new_street = street
    new_street = new_street.titleize if (new_street == new_street.downcase) || (new_street == new_street.upcase)
    new_street.squish
  end
  normalizes :street2, with: ->(street2) do
    new_street2 = street2
    new_street2 = new_street2.titleize if (new_street2 == new_street2.downcase) || (new_street2 == new_street2.upcase)
    new_street2.squish
  end
  normalizes :zip_code, with: ->(zip_code) { zip_code.squish.sub(/\A(\d{5}) (\d{4})\z/, '\1-\2') }

  scope :with_zip_code, ->(zip_code) do
    zip_code = normalize_value_for(:zip_code, zip_code.to_s).delete(' ').split('-').first.to_s.upcase

    where("upper(split_part(replace(addresses.zip_code, ' ', ''), '-', 1)) = ?", zip_code)
  end

  validate :region_matches_country
  validate :validate_ref, if: -> { ref.present? && ref_changed? }
  validate :validate_street, if: -> { street.present? && country.present? }
  validate :validate_street_attributes
  validate :validate_zip_code, if: -> { zip_code.present? && country.present? && (zip_code_changed? || country_alpha2_changed?) }

  validates :city, presence: true
  validates :zip_code, presence: true, if: :postal_code?

  def blank_to_nil(obj) = obj == '' ? nil : obj
  def commercial? = business?
  def full_address? = street.present? && city.present? && region.present?
  def locality = "#{city}, #{region.abbreviation}".sub(',  ', '')
  def moved? = persisted? && POSTAL_ATTRIBUTES.any? { will_save_change_to_attribute?(it) }
  def postal_code? = country.nil? || country.postal_code

  def pretty(seperator)
    str = ''.dup
    str << "#{ref}#{seperator}" if ref.present?
    str << "#{street}#{seperator}" if street.present?
    str << "#{street2}#{seperator}" if street2.present?

    str << if region.present?
             "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')
           else
             "#{city}, #{zip_code}".sub(',  ', '')
           end
    str
  end

  def proper(seperator)
    str = ''.dup
    str << "#{street}#{seperator}" if street.present?
    str << "#{street2}#{seperator}" if street2.present?
    str << "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')
    str
  end

  def restaurant? = types.include?('restaurant')
  def shipment = shipper_shipment || receiver_shipment

  def standardize
    return unless moved? || postal_address_changed? || (full_address? && will_save_change_to_name?)
    return if [name, to_postal_address] == @standardized

    Address::StandardizeService.new(address: self).call
    @standardized = [name, to_postal_address]
  end

  def time_zone = ActiveSupport::TimeZone.new(time_zone_name.presence || 'America/Los_Angeles')

  def to_accounting_address
    Accounting::Address.new(
      city:,
      country: country_alpha2,
      line1: street,
      line2: street2,
      postal_code: zip_code,
      region: region.abbreviation
    )
  end

  def to_postal_address
    {
      address_lines: [street, street2].compact_blank,
      administrative_area: region&.abbreviation,
      locality: city,
      postal_code: zip_code,
      region_code: country_alpha2
    }
  end

  def to_transponder_graphql_input
    {
      address1: street,
      city:,
      country: {
        alpha3: country.alpha3
      },
      postalCode: zip_code,
      regionAbbreviation: region.abbreviation
    }
  end

  def types = (super + inferred_types).uniq.sort

  private

  def airport? = AIRPORT_WORDS.any? { |word| "#{street} #{street2}".downcase.include?(word) }
  def inferred_types = [('airport' if airport?), ('military_site' if military?)].compact
  def military? = zip_code.present? && zip_code.start_with?(*MILITARY_POSTAL_CODES)
  def postal_address_changed? = full_address? && POSTAL_ATTRIBUTES.any? { |attribute| will_save_change_to_attribute?(attribute) }

  def region_matches_country
    return if region.blank? || country.blank?

    errors.add(:region, "isn't within #{country.name}") unless region.country == country
  end

  def set_country
    return if region.blank? || country.present?

    self.country = region.country
  end

  def validate_ref
    case ref.downcase
    when 'none', 'verbal' then errors.add(ref, "cannot be “#{value}”")
    end

    ['C/O', 'P/O', 'P/U', 'Ref:', 'S/O', '#'].each do |prefix|
      matched_prefix = ref.match(/\A#{Regexp.escape(prefix)}/i)
      next if matched_prefix.blank?

      errors.add(:ref, "cannot start with “#{matched_prefix}”")
    end
  end

  def validate_street
    return if country.valid_street?(street)

    errors.add(:street, "is not valid for #{country.name}")
  end

  def validate_street_attributes
    %i[street street2].each do |attribute|
      next unless public_send("#{attribute}_changed?")

      value = public_send(attribute)
      next if value.blank?

      matched_prefix = value.match(/\A#{Regexp.escape('C/O')}/i)
      errors.add(attribute, "cannot contain “#{matched_prefix}”") if matched_prefix.present?

      ['Re:', 'Ref:', 'Release'].each do |prefix|
        matched_prefix = value.match(/\A#{Regexp.escape(prefix)}/i)
        next if matched_prefix.blank?

        errors.add(attribute, "cannot start with “#{matched_prefix}”")
      end
    end
  end

  def validate_zip_code
    return if country.valid_postal_code?(zip_code)

    errors.add(:zip_code, "is not valid for #{country.name}")
  end
end
