class FetchPaymentTransactionAccountingBillJob < ApplicationJob
  def perform(payment_transaction) = payment_transaction.update_from_accounting_bill
end
