# == Schema Information
#
# Table name: shipment_accessorials
#
# @!attribute id
#   @return []
# @!attribute accessorial_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_shipment_accessorials_on_accessorial_id  (accessorial_id)
#  index_shipment_accessorials_on_shipment_id     (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (accessorial_id => accessorials.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
class ShipmentAccessorial < ApplicationRecord
  belongs_to :accessorial
  belongs_to :shipment
end
