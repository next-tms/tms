class ProblemPolicy < ApplicationPolicy
  relation_scope { |relation| broker? ? relation.merge(Problem.by_any_role(*authorizable.roles)) : relation.none }

  def view? = broker? && record.present? && Problem.by_any_role(*authorizable.roles).exists?(id: record.id)
end
