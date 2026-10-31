# Provides access to broker's Stripe API
class Address::OpenStreetMapVerifyService
  attr_reader :address_key, :country, :street

  def initialize(address_key:, country:, street:)
    @address_key = address_key
    @country = country
    @street = street
  end

  def call
    Rails.logger.info('Calling OpenStreetMap API')

    result = OpenStreetMap::Client.new.search(
      q: "#{address_key}, #{country.name}",
      format: 'json',
      addressdetails: '1',
      accept_language: 'en'
    )&.first

    accurate = result.is_a?(Hash) && street.scan(/\d+/).map { |d| result['display_name'].include?(d) }.all?(true)
    return unless accurate

    result
  end
end
