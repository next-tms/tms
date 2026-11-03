class BrokerCustomerPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if broker?
    next relation.where(id: companyable) if customer?

    relation.none
  end

  def view? = broker? || (customer? && record == companyable)
  def view_internal_notes? = broker?
  def view_markup? = broker?
end
