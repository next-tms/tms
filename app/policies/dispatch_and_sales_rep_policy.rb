class DispatchAndSalesRepPolicy < ApplicationPolicy
  def accounts_and_claims_show?
    user? && (authorizable.any_role?(:accounts_payable, :accounts_receivable, :claims) || dispatcher_and_sales_rep?)
  end

  def accounts_show? = user? && (authorizable.any_role?(:accounts_payable, :accounts_receivable) || dispatcher_and_sales_rep?)
  def show? = user? && (authorizable.role?(:dispatch) || authorizable.sales_rep_for?(record.broker_customer))

  private

  def dispatcher_and_sales_rep? = authorizable.dispatcher_for?(record) || authorizable.sales_rep_for?(record.broker_customer)
end
