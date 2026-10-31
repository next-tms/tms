class PushPaymentTransactionToAccountingJob < ApplicationJob
  def perform(payment_transaction)
    return payment_transaction.update_accounting_bill if payment_transaction.accounting_bill.present?

    payment_transaction.create_accounting_bill
  end
end
