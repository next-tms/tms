class AddressSerializer < ActiveModel::Serializer
  attributes :street, :street2, :city, :state, :zip_code, :latitude, :longitude, :time_zone
end
