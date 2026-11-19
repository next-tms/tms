class GeocoderController < ApplicationController
  def fetch_address_by_broker_customer
    @address = BrokerCustomer.find(params[:broker_customer_id]).primary_pickup_address
    render_error('No Address Found') if @address.blank?
  end

  def validate_address
    @verification = Geo.verify(**Address.new(address_params).to_postal_address)
    render_error('No Address Found') unless @verification&.verified
  end

  private

  def address_params = params.expect(geocoder: %i[city country_alpha2 region_iso31662 street zip_code])
  def render_error(error) = render(:error, locals: { error: })
end
