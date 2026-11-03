class APIKeyPolicy < ApplicationPolicy
  alias_rule :view?, to: :manage?

  relation_scope do |relation|
    next relation.where(authorizable:) unless accounts_payable?

    relation.where(authorizable:).or(relation.where(authorizable_type: 'BrokerCarrier'))
  end

  def manage? = record.authorizable == authorizable || (record.broker_carrier? && accounts_payable?)

  private

  def accounts_payable? = broker? && authorizable.any_role?(:accounts_payable, :root)
end
