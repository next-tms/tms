class ShipmentPolicy < ActionPolicy::Base
  authorize :user, optional: true

  relation_scope { |relation| relation.accessible_by(user) }

  def create? = user.present? && user.customer?
  def manage? = user.present? && record.accessible_by?(user)
  def view? = manage?
end
