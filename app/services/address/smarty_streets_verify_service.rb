# Provides access to broker's Stripe API
class Address::SmartyStreetsVerifyService
  attr_reader :address_key

  def initialize(address_key:)
    @address_key = address_key
  end

  def call
    Rails.logger.info('Calling SmartyStreet API')
    address_data = MainStreet::AddressVerifier.new(address_key).result&.data
    # Error Response is an Arary e.g ['errors', { id: 123, message: 'ERR'} ]
    return address_data&.to_hash unless address_data.is_a?(Array)

    error_key, error_data = address_data
    return unless error_key == 'errors'

    Honeybadger.notify(error_message: error_data.first['message'])
    nil
  end
end
