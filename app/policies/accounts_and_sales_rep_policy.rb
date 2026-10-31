class AccountsAndSalesRepPolicy < ActionPolicy::Base
  # By default, Action Policy uses context[:current_user] as the user authorization context.
  def accounts_receivable_show?
    user.any_role?(['accounts_receivable', 'root']) ||
      user.sales_rep_for?(record)
  end

  def accounts_receivable_and_sales_rep_for_all_show?
    user.sales_rep_for?(record) &&
      user.role?(:sales_rep_for_all_broker_customers) &&
      user.role?(:accounts_receivable)
  end
end
