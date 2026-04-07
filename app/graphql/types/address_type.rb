module Types
  class AddressType < Types::BaseObjectWithTimestamp
    description 'GraphQL Object for Address Model'

    field :city, String, null: true
    field :country, Types::CountryType, null: false
    field :google_places_spot_cached, String, null: true
    field :google_places_spot_updated_at, GraphQL::Types::ISO8601DateTime
    field :id, ID, null: false
    field :latitude, Float, null: true
    field :longitude, Float, null: true
    field :open_street_map_result_cached, String
    field :open_street_map_result_updated_at, GraphQL::Types::ISO8601DateTime
    field :original_attributes, String, null: true
    field :ref, String, null: true
    field :region, Types::RegionType, null: true
    field :smarty_streets_result_updated_at, GraphQL::Types::ISO8601DateTime
    field :standardized_address_id, ID, null: true
    field :street, String, null: true
    field :street2, String, null: true
    field :time_zone_name, String, null: true
    field :verification_info, String, null: true
    field :zip_code, String, null: true
  end
end
