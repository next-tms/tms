# frozen_string_literal: true

module Types
  class AddressType < Types::BaseObjectWithTimestamp
    field :id, ID, null: false
    field :city, String, null: true
    field :country, Types::CountryType, null: false
    field :region, Types::RegionType, null: true
    field :google_places_spot_cached, String, null: true
    field :latitude, Float, null: true
    field :longitude, Float, null: true
    field :open_street_map_result_cached, String
    field :original_attributes, String, null: true
    field :ref, String, null: true
    field :standardized_address_id, ID, null: true
    field :street, String, null: true
    field :street2, String, null: true
    field :time_zone_name, String, null: true
    field :verification_info, String, null: true
    field :zip_code, String, null: true
    field :open_street_map_result_updated_at, GraphQL::Types::ISO8601DateTime
    field :smarty_streets_result_updated_at, GraphQL::Types::ISO8601DateTime
    field :google_places_spot_updated_at, GraphQL::Types::ISO8601DateTime
  end
end
