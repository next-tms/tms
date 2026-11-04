class AccountingPolicy < ApplicationPolicy
  def accounts_payable_show? = authorizable.any_role?(:accounts_payable, :root)
  def accounts_receivable_show? = authorizable.any_role?(:accounts_receivable, :root)
  def root_show? = authorizable.role?(:root)
  def show? = authorizable.role?(:root)
end
