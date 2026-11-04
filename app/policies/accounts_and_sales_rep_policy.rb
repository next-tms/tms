class AccountsAndSalesRepPolicy < ApplicationPolicy
  def accounts_receivable_and_sales_rep_for_all_show?
    authorizable.sales_rep_for?(record) &&
      authorizable.role?(:sales_rep_for_all_broker_customers) &&
      authorizable.role?(:accounts_receivable)
  end

  def accounts_receivable_show? = authorizable.any_role?(['accounts_receivable', 'root']) || authorizable.sales_rep_for?(record)
end
