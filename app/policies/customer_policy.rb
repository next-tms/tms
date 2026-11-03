class CustomerPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if broker?
    next relation.where(id: companyable.customer_id) if customer?

    relation.none
  end

  def view? = broker? || (customer? && record == companyable.customer)
end
