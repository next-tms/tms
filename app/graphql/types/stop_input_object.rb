module Types
  class StopInputObject < Types::BaseInputObject
    description 'GraphQL Input Object for Shipper and Receiver Arguments'

    argument :address, Types::AddressInputObject, required: false
    argument :contact_email, String, required: false
    argument :contact_name, String, required: false
    argument :contact_phone, String, required: false
    argument :name, String, required: false

    def shipment_attributes(role)
      {
        "#{role}_address_attributes": { **address&.to_h, name: }.compact.presence,
        "#{role}_contact_email": contact_email,
        "#{role}_contact_name": contact_name,
        "#{role}_contact_phone": contact_phone
      }.compact
    end
  end
end
