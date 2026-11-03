class TrackingEventPolicy < ApplicationPolicy
  def view? = broker? || record.public?
end
