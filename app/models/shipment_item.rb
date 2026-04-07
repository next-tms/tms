# == Schema Information
#
# Table name: shipment_items
#
# @!attribute id
#   @return []
# @!attribute item_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_shipment_items_on_item_id      (item_id)
#  index_shipment_items_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
class ShipmentItem < ApplicationRecord
  belongs_to :item
  belongs_to :shipment
end
