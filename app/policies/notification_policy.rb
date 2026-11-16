class NotificationPolicy < ApplicationPolicy
  alias_rule :view?, to: :manage?

  relation_scope { |relation| relation.where(recipient: authorizable) }

  def manage? = record.recipient == authorizable
end
