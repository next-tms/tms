# frozen_string_literal: true

class PushPaymentTransactionToQuickbooksJob < ApplicationJob
  def perform(payment_transaction)
    return !!payment_transaction.update_quickbooks_bill unless payment_transaction.quickbooks_bill.blank?

    !!payment_transaction.create_quickbooks_bill
  end
end
