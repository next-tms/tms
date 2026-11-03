module Types
  class LocationInputObject < Types::BaseInputObject
    description 'GraphQL Input Object for Shipper and Receiver Arguments'

    argument :address, Types::AddressInputObject, required: false
    argument :contact_email, String, required: false
    argument :contact_name, String, required: false
    argument :contact_phone, String, required: false
    argument :name, String, required: false

    def shipment_attributes(prefix, address_id)
      {
        "#{prefix}_address_attributes": address&.address_attributes&.merge(id: address_id),
        "#{prefix}_contact_email": contact_email,
        "#{prefix}_contact_name": contact_name,
        "#{prefix}_contact_phone": contact_phone,
        "#{prefix}_name": name
      }.compact
    end
  end
end
