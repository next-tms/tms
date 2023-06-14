# frozen_string_literal: true

class GeocoderController < ApplicationController
  def fetch_details_by_zip_code
    locations = Geocoder.search(params[:postal_code])
    render json: { error: 'No Location Found' } and return unless locations.present?

    selected_country = params[:country]
    selected_country = 'United States' if selected_country == 'United States of America'

    begin
      matched_location = locations.find { |loc| loc.data.dig('address', 'country') == selected_country }
    rescue TypeError => e
      # TODO: Watch for Honeybadger errors. Cannot replicate issue on development.
      Honeybadger.notify(e, locations: locations)
      render json: { error: 'No Location Found' } and return
    end

    render json: { error: 'No Location Found' } and return unless matched_location

    address = matched_location.data['address']

    render json: { city: address['city'] || address['town'], state: address['state'] }
  end

  def fetch_address_by_broker_customer
    broker_customer = BrokerCustomer.find(params[:broker_customer_id])
    render json: { error: "No BrokerCustomer Found" } and return if broker_customer.blank?

    address = broker_customer.primary_pickup_address
    render json: { error: "No Address Found" } and return if address.blank?

    if address.standardized_address_id.blank?
      address.find_or_build_standardized_address && address.save
    end

    render json: {
      city: address.city,
      state: address.region.name,
      street: address.street,
      street2: address.street2,
      zip_code: address.zip_code,
      standardized_address_id: address.reload.standardized_address_id
    }
  end

  def validate_address
    standardized_address = Address::FindOrCreateViaSmartyStreetsService.new(**params).call
    render json: { error: "No Address Found" } and return unless standardized_address

    render json: { standardized_address_id: standardized_address.id }
  end
end
