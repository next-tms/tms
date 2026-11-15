class CopyShipmentNamesToAddresses < ActiveRecord::Migration[8.1]
  class Address < ActiveRecord::Base
    self.table_name = 'addresses'
  end

  class Setting < ActiveRecord::Base
    self.table_name = 'settings'
  end

  class Shipment < ActiveRecord::Base
    self.table_name = 'shipments'
  end

  OWNERS = {
    'broker_carriers' => ['check_mailing_address_id'],
    'broker_customers' => ['office_address_id', 'primary_pickup_address_id'],
    'carriers' => ['broker_billing_address_id', 'check_mailing_address_id'],
    'terminals' => ['address_id'],
    'tracking_events' => ['address_id']
  }.freeze

  def down
    Shipment.find_each do |shipment|
      shipment.update_columns(
        receiver_name: Address.find_by(id: shipment.receiver_address_id)&.name,
        shipper_name: Address.find_by(id: shipment.shipper_address_id)&.name
      )
    end
  end

  def up
    claimed = owned_address_ids
    original_names = {}

    Shipment.find_each do |shipment|
      claim(shipment, :receiver, claimed, original_names)
      claim(shipment, :shipper, claimed, original_names)
    end
  end

  private

  def claim(shipment, role, claimed, original_names)
    address = Address.find_by(id: shipment["#{role}_address_id"])
    return if address.nil?

    original_names[address.id] = address.name unless original_names.key?(address.id)

    if claimed.add?(address.id).nil?
      address = address.dup.tap { it.update!(name: original_names[address.id]) }
      shipment.update_columns("#{role}_address_id" => address.id)
    end

    address.update_columns(name: shipment["#{role}_name"]) if shipment["#{role}_name"].present?
  end

  def owned_address_ids
    ids = OWNERS.flat_map do |table, columns|
      model = Class.new(ActiveRecord::Base) { self.table_name = table }
      columns.flat_map { model.where.not(it => nil).pluck(it) }
    end

    Set.new(ids + Setting.where(key: 'mailing_address').pluck(:value).compact_blank.map(&:to_i))
  end
end
