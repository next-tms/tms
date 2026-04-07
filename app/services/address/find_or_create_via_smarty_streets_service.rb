# Provides access to broker's Stripe API
class Address::FindOrCreateViaSmartyStreetsService
  attr_reader :street, :street2, :city, :zip_code, :region_id

  def initialize(street:, street2: nil, city:, zip_code:, region_id:)
    @street = street
    @street2 = street2
    @city = city
    @zip_code = zip_code
    @region_id = region_id
  end

  def call
    region = Region.find(region_id)
    address_key = build_address_key(region)

    standardized_address = StandardizedAddress.where('lower(key) LIKE ?', "%#{address_key.downcase}%")&.first
    return standardized_address if standardized_address.present?

    verified_address_data = Address::SmartyStreetsVerifyService.new(address_key:).call
    return unless verified_address_data

    new_standardized_address = StandardizedAddress.new(
      smarty_streets_result_cached: verified_address_data,
      smarty_streets_result_updated_at: Time.current,
      street:,
      street2:,
      city:,
      postal_code: zip_code,
      region:,
      country: region.country,
      key: address_key,
    )

    new_standardized_address.time_zone_name = 'America/Los_Angeles' if Rails.env.test?
    new_standardized_address.skip_smarty_streets_result_api_request = true
    return unless new_standardized_address.save(validate: !Rails.env.test?)

    new_standardized_address
  end

  def build_address_key(region)
    str = ''.dup
    str << "#{street}, " if street.present?
    str << "#{street2}, " if street2.present?
    str << "#{city}, #{region.abbreviation} #{zip_code}".sub(',  ', '')

    str
  end
end
