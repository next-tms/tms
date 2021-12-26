class Broker::ShipmentSerializer < ActiveModel::Serializer
  attributes :broker, :carrier, :shipper_address, :receiver_address, :updated_at

  def address(address)
    {
      street: address.street,
      street2: address.street2,
      city: address.city,
      state: address.region.abbreviation,
      zip_code: address.zip_code,
      types: address.types
    }
  end

  def receiver_address
    address(object.receiver_address)
  end

  def shipper_address
    address(object.shipper_address)
  end

  # Reveals the sub-broker when shipment is double-brokered
  def broker
    if !object.broker_carrier.blank? && object.broker_carrier.carrier.acts_as_broker?
      return {
        account: object.broker_carrier.account,
        name: object.broker_carrier.carrier.name,
        pro: object.pro,
        scac: object.broker_carrier.carrier.scac
      }
    end

    { account: nil, name: nil, pro: nil, scac: nil }
  end

  def carrier
    account = nil
    carrier = nil
    pro = nil

    unless object.broker_carrier.blank?
      if object.broker_carrier.carrier.acts_as_broker? && !object.tracking_carrier.blank?
        carrier = object.tracking_carrier
        pro = object.tracking_carrier_pro
      else
        carrier = object.broker_carrier.carrier
        pro = object.pro
      end
    end

    {
      name: carrier.name,
      scac: carrier.scac,
      account: account,
      pro: pro
    }
  end
end
