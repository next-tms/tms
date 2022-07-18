# frozen_string_literal: true

class GeocoderController < ApplicationController
  def fetch_details_by_zip_code
    locations = Geocoder.search(params[:zip_code])
    render json: { error: 'No Location Found' } and return unless locations.present?

    selected_country = params[:country]
    selected_country = 'United States' if selected_country == 'United States of America'

    matched_location = locations.find { |loc| loc.data.dig('address', 'country') == selected_country }
    render json: { error: 'No Location Found' } and return unless matched_location

    address = matched_location.data['address']

    render json: { city: address['city'] || address['town'], state: address['state'] }
  end
end
