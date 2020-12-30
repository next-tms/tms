class ItemSerializer < ActiveModel::Serializer
  attributes :quantity, :packaging, :desc, :l, :w, :h, :weight

  def packaging
    ActiveModel::SerializableResource.new(object.packaging)
  end
end
