class TrackingEventPolicy < ApplicationPolicy
  def view? = broker? || record.public? || tracking_carrier?

  private

  def tracking_carrier? = carrier? && record.shipment&.tracking_carrier_id == companyable.id
end
