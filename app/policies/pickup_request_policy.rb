class PickupRequestPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation.none unless user?

    other_shipments = Shipment.where.not(id: authorizable.shipments).where.not(pickup_request_id: nil)
    relation.where(id: authorizable.shipments.select(:pickup_request_id)).where.not(id: other_shipments.select(:pickup_request_id))
  end

  def manage? = customer?
  def view? = user?
end
