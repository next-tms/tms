module Types
  class AddressType < Types::BaseObjectWithTimestamp
    description 'GraphQL Object for Address Model'

    field :business, Boolean, null: true
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
    field :permanently_closed, Boolean, null: true
    field :place_id, String, null: true
    field :po_box, Boolean, null: true
    field :ref, String, null: true
    field :region, Types::RegionType, null: true
    field :residential, Boolean, null: true
    field :smarty_streets_result_updated_at, GraphQL::Types::ISO8601DateTime
    field :street, String, null: true
    field :street2, String, null: true
    field :time_zone_name, String, null: true
    field :types, [String], null: false
    field :verification_info, String, null: true
    field :zip_code, String, null: true
  end
end
