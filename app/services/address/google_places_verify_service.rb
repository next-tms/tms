# Provides access to broker's Stripe API
class Address::GooglePlacesVerifyService
  attr_reader :address_key, :street

  def initialize(address_key:, street:)
    @address_key = address_key
    @street = street
  end

  def call
    return if ENV['GOOGLE_API_KEY'].blank?

    Rails.logger.info('Calling Google Places API')

    begin
      retries ||= 0
      result = GooglePlaces::Client.new(ENV.fetch('GOOGLE_API_KEY')).spots_by_query(address_key)&.first
    rescue GooglePlaces::APIConnectionError
      retries += 1
      sleep(1)
      retry if retries < 3

      raise
    rescue GooglePlaces::RequestDeniedError => e
      Sentry.capture_exception(e)

      return
    end

    accurate = result.is_a?(GooglePlaces::Spot) &&
               street.scan(/\d+/).map { |d| result.formatted_address.include?(d) }.all?(true)

    return unless accurate

    result
  end
end
