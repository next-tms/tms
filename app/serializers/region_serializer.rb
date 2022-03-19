class RegionSerializer < ActiveModel::Serializer
  attributes :abbreviation, :country, :name

  def country
    ActiveModel::SerializableResource.new(object.country)
  end
end
