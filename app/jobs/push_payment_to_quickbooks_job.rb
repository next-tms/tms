# frozen_string_literal: true

class PushPaymentToQuickbooksJob < ApplicationJob
  def perform(payment)
    return !!payment.update_quickbooks_bill_payment unless payment.quickbooks_bill_payment.blank?

    !!payment.create_quickbooks_bill_payment
  end
end
