class APIKeyPolicy < ApplicationPolicy
  alias_rule :view?, to: :manage?

  relation_scope do |relation|
    next relation.where(user: authorizable) unless accounts_payable?

    relation.where(user: authorizable).or(relation.where(user: User.carrier))
  end

  def manage? = record.user == authorizable || (accounts_payable? && record.user&.carrier?)

  private

  def accounts_payable? = broker? && authorizable.any_role?(:accounts_payable, :root)
end
