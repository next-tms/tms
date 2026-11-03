class PaymentTransactionPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if accounts_payable?
    next relation.where(broker_carrier: companyable) if carrier?

    relation.none
  end

  def manage? = broker_carrier?

  def view?
    return false unless record
    return true if accounts_payable?

    carrier? && record.broker_carrier == companyable
  end

  private

  def accounts_payable? = broker? && authorizable.any_role?(:accounts_payable, :root)
end
