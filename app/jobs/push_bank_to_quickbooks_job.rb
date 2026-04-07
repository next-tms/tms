class PushBankToQuickbooksJob < ApplicationJob
  def perform(bank)
    return !!bank.update_quickbooks_account unless bank.quickbooks_account.blank?

    !!bank.create_quickbooks_account
  end
end
