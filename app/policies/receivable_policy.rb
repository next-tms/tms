class ReceivablePolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if accounts_receivable?
    next relation.where(shipment: Shipment.where(broker_customer: companyable)) if customer?

    relation.none
  end

  def view?
    return false unless record
    return true if accounts_receivable?

    customer? && record.shipment.broker_customer == companyable
  end

  private

  def accounts_receivable? = broker? && authorizable.any_role?(:accounts_receivable, :root)
end
