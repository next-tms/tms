class ShipmentPolicy < ActionPolicy::Base
  # By default, Action Policy uses context[:current_user] as the user authorization context.
  def show?
    record.accessible_by?(user)
  end
end
