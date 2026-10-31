class GeocoderController < ApplicationController
  def fetch_details_by_zip_code
    locations = Geocoder.search(params[:postal_code])
    return render_error('No Location Found') if locations.blank?

    selected_country = params[:country]
    selected_country = 'United States' if selected_country == 'United States of America'

    begin
      matched_location = locations.find { |location| location.data.dig('address', 'country') == selected_country }
    rescue TypeError => e
      # TODO: Watch for Sentry errors. Cannot replicate issue on development.
      Sentry.capture_exception(e, extra: { locations: })
      return render_error('No Location Found')
    end

    return render_error('No Location Found') unless matched_location

    @address = matched_location.data['address']
  end

  def fetch_address_by_broker_customer
    @address = BrokerCustomer.find(params[:broker_customer_id]).primary_pickup_address
    return render_error('No Address Found') if @address.blank?

    @address.find_or_build_standardized_address && @address.save if @address.standardized_address_id.blank?
    @address.reload
  end

  def validate_address
    @standardized_address = Address::FindOrCreateViaSmartyStreetsService.new(**address_params.to_h.deep_symbolize_keys).call
    render_error('No Address Found') unless @standardized_address
  end

  private

  def address_params = params.expect(geocoder: %i[street city zip_code region_iso31662])
  def render_error(error) = render(:error, locals: { error: })
end
