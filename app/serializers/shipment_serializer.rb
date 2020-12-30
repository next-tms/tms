class ShipmentSerializer < ActiveModel::Serializer
  attributes :id, :fingerprint, :shipper_name, :shipper_reference, :customer_reference, :pro, :picked_up, :receiver_name, :shipper_contact_name, :shipper_contact_phone, :shipper_contact_email, :receiver_contact_name, :receiver_contact_phone, :receiver_contact_email, :shipper_address, :receiver_address, :pickup_on, :delivered_at, :created_at, :updated_at, :deliver_by, :total_charges_cents, :total_charges_currency, :picked_up_at, :out_for_delivery_at, :value_cents, :value_currency, :bol_notes, :canceled_at, :promised_delivery_by, :truckload, :pending_appointment_since, :delivery_appointment_at, :delivery_appointment_on, :carrier, :pickup_hours_start_at, :pickup_hours_end_at, :delivery_hours_start_at, :delivery_hours_end_at, :applied_rate, :items, :rates

  def applied_rate
    ActiveModel::SerializableResource.new(object.applied_rate)
  end

  def carrier
    ActiveModel::SerializableResource.new(object.carrier)
  end

  def items
    ActiveModel::SerializableResource.new(object.items, each_serializer: ItemSerializer)
  end

  def rates
    ActiveModel::SerializableResource.new(object.rates, each_serializer: RateSerializer)
  end

  def receiver_address
    ActiveModel::SerializableResource.new(object.receiver_address)
  end

  def shipper_address
    ActiveModel::SerializableResource.new(object.shipper_address)
  end

  def id
    object.load_id
  end
end
