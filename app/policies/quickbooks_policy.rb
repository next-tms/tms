class QuickbooksPolicy < ActionPolicy::Base
  def accounts_payable_show?
    broker_and_intuit_account_present? &&
    user.any_role?(:accounts_payable)
  end

  def accounts_receivable_show?
    broker_and_intuit_account_present? &&
    user.any_role?(:accounts_receivable)
  end

  def root_show?
    broker_and_intuit_account_present? &&
    user.role?(:root)
  end

  private

  def broker_and_intuit_account_present?
    user.broker? && user.broker.intuit_account.present?
  end
end
