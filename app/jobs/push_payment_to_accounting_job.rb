class PushPaymentToAccountingJob < ApplicationJob
  def perform(payment)
    return !!payment.update_accounting_bill_payment if payment.accounting_bill_payment.present?

    !!payment.create_accounting_bill_payment
  end
end
