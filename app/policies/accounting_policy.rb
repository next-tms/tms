class AccountingPolicy < ActionPolicy::Base
  # By default, Action Policy uses context[:current_user] as the user authorization context.
  def accounts_payable_show? = user.any_role?(:accounts_payable, :root)
  def accounts_receivable_show? = user.any_role?(:accounts_receivable, :root)
  def root_show? = user.role?(:root)
  def show? = user.role?(:root)
end
