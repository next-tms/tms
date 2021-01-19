class RateSerializer < ActiveModel::Serializer
  attributes :uid, :carrier, :charge, :charge_currency, :expires_at, :transit_days, :incomplete, :shipment_fingerprint

  def carrier
    ActiveModel::SerializableResource.new(object.carrier)
  end

  def charge
    object.broker_customer.carrier_charge_calculator(carrier_cost: object.cost, shipment: object.shipment).to_f
  end

  def charge_currency
    object.cost_currency
  end

  def uid
    object.uid
  end
end
