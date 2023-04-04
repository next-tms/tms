class DispatchAndSalesRepPolicy < ActionPolicy::Base
  # By default, Action Policy uses context[:current_user] as the user authorization context.
  def show?
    user.role?(:dispatch) ||
    user.sales_rep_for?(record.broker_customer)
  end

  def accounts_show?
    user.any_role?(:accounts_payable, :accounts_receivable) ||
    dispatcher_and_sales_rep?
  end

  def accounts_and_claims_show?
    user.any_role?(:accounts_payable, :accounts_receivable, :claims) ||
    dispatcher_and_sales_rep?
  end

  private

  def dispatcher_and_sales_rep?
    user.dispatcher_for?(record) ||
    user.sales_rep_for?(record.broker_customer)
  end
end
