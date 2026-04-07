class FetchPaymentTransactionQuickbooksBillJob < ApplicationJob
  def perform(payment_transaction)
    payment_transaction.update_from_quickbooks_bill
  end
end
