class CountrySerializer < ActiveModel::Serializer
  attributes :alpha2_code, :alpha3_code, :name, :un_code
end
