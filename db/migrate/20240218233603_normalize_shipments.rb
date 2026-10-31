class NormalizeShipments < ActiveRecord::Migration[7.1]
  ATTRIBUTES = %i[
    bol
    customer_reference
    pickup_confirmation
    pro
    quote_id
    receiver_contact_email
    receiver_contact_name
    receiver_name
    shipper_contact_email
    shipper_contact_name
    shipper_name
    shipper_reference
  ].freeze

  def up
    Shipment.find_each do |shipment|
      ATTRIBUTES.each do |attribute|
        shipment.normalize_attribute(attribute)
        next unless shipment.public_send("#{attribute}_changed?")

        shipment.update_columns({ attribute => shipment.public_send(attribute) })
      end
    end
  end

  def down; end
end
