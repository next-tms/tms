class ReevaluateShipmentProblemsJob < ApplicationJob
  def perform = ProblematicJob.perform_later(shipment_ids, type: 'Shipment')

  private

  def shipment_ids
    problematic_ids = Problem.unresolved.where(resolvable_type: 'Shipment').pluck(:resolvable_id)

    (Shipment.pending_pickup.ids + Shipment.pending_delivery.ids + problematic_ids).uniq
  end
end
