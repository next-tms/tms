class PickupRequestPolicy < ActionPolicy::Base
  authorize :user, optional: true

  relation_scope do |relation|
    next relation.none unless user

    other_shipments = Shipment.where.not(id: user.shipments).where.not(pickup_request_id: nil)
    relation.where(id: user.shipments.select(:pickup_request_id)).where.not(id: other_shipments.select(:pickup_request_id))
  end

  def manage? = user.present? && user.customer?
  def view? = user.present?
end
