class APIKeyPolicy < ActionPolicy::Base
  relation_scope do |relation|
    next relation.where(authorizable: user) unless accounts_payable?

    relation.where(authorizable: user).or(relation.where(authorizable_type: 'BrokerCarrier'))
  end

  def manage? = record.authorizable == user || (record.broker_carrier? && accounts_payable?)
  def view? = manage?

  private

  def accounts_payable? = user.broker? && user.any_role?(:accounts_payable, :root)
end
