# frozen_string_literal: true

module Types
  class AddressInputObject < Types::BaseInputObject
    description 'GraphQL Input Object for Address Arguments'

    argument :city, String, required: true
    argument :region_iso31662, Types::Iso31662Type, required: true
    argument :street, String, required: true
    argument :zip_code, String, required: true
  end
end
