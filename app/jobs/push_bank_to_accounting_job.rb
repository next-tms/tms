class PushBankToAccountingJob < ApplicationJob
  def perform(bank)
    return bank.update_accounting_account if bank.accounting_account.present?

    bank.create_accounting_account
  end
end
