class EventSerializer < ActiveModel::Serializer
  attributes :code, :name

  def code
    object.active_shipping_code
  end
end
