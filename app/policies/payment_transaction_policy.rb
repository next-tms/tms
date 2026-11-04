class PaymentTransactionPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if accounts_payable?
    next relation.where(broker_carrier: companyable.broker_carriers) if carrier?

    relation.none
  end

  def manage? = carrier? && (record.broker_carrier.nil? || record.broker_carrier.carrier == companyable)

  def view?
    return false unless record
    return true if accounts_payable?

    carrier? && record.broker_carrier&.carrier == companyable
  end

  private

  def accounts_payable? = broker? && authorizable.any_role?(:accounts_payable, :root)
end
