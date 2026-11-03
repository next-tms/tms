module Types
  class AddressInputObject < Types::BaseInputObject
    description 'GraphQL Input Object for Address Arguments'

    argument :city, String, required: true
    argument :region_iso31662, Types::Iso31662Type, required: true
    argument :street, String, required: false
    argument :street2, String, required: false
    argument :zip_code, String, required: true

    def address_attributes = { city:, region_iso31662:, street:, street2:, zip_code: }.compact
  end
end
