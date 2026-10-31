module Payment::Accounting
  extend ActiveSupport::Concern

  included { after_commit :push_to_accounting }

  def create_accounting_bill_payment
    return unless Accounting.connected? && Accounting.supports?(:bill_payment) && paid?
    return update_accounting_bill_payment if accounting_bill_payment.present?

    result = Accounting.record_class(:bill_payment).create(to_accounting_bill_payment.attributes)
    return @accounting_bill_payment = nil if result.blank?

    update_columns(accounting_bill_payment_id: result.id) # rubocop:disable Rails/SkipsModelValidations
    @accounting_bill_payment = result
  end

  def destroy_accounting_bill_payment
    return unless Accounting.connected? && Accounting.supports?(:bill_payment)
    return false if accounting_bill_payment.blank?

    accounting_bill_payment.destroy
    update_columns(accounting_bill_payment_id: nil) # rubocop:disable Rails/SkipsModelValidations
    @accounting_bill_payment = nil
  end

  def accounting_bill_payment
    return unless Accounting.connected? && Accounting.supports?(:bill_payment)
    return @accounting_bill_payment if @accounting_bill_payment.present?
    return if accounting_bill_payment_id.blank?

    @accounting_bill_payment = Accounting.record_class(:bill_payment).find(accounting_bill_payment_id)
  end

  def to_accounting_bill_payment
    broker_carrier.create_accounting_vendor if broker_carrier.accounting_vendor_id.blank?
    bank.create_accounting_account if bank.accounting_account_id.blank?

    Accounting::BillPayment.new(
      account_id: bank.accounting_account_id,
      account_name: bank.accounting_account.name,
      document_number: id,
      line_items: accounting_bill_payment_line_items,
      pay_type: bank.credit_card? ? :credit_card : :check,
      private_note: accounting_bill_payment_private_note,
      total: Money.new(payment_transactions.sum(:paid_cents)),
      vendor_id: broker_carrier.accounting_vendor_id
    )
  end

  def update_from_accounting_bill_payment
    return update_columns(paid_on: nil) if accounting_bill_payment.blank? # rubocop:disable Rails/SkipsModelValidations

    update_columns(paid_on: accounting_bill_payment.transaction_date) # rubocop:disable Rails/SkipsModelValidations
    reload
  end

  def update_accounting_bill_payment
    return destroy_accounting_bill_payment unless paid?
    return unless Accounting.connected? && Accounting.supports?(:bill_payment)
    return create_accounting_bill_payment if accounting_bill_payment.blank?

    @accounting_bill_payment = Accounting.record_class(:bill_payment).new(accounting_bill_payment_id,
                                                                          **to_accounting_bill_payment.attributes).save
  end

  private

  def accounting_bill_payment_line_items
    unpaid = payment_transactions.where('balance_cents > ?', 0)
    unpaid.where(accounting_bill_id: nil).find_each(&:create_accounting_bill)

    unpaid.map do |payment_transaction|
      Accounting::LineItem.new(
        amount: payment_transaction.paid_cents.to_f / 100,
        description: payment_transaction.shipment.pro.presence,
        linked_transactions: [{ txn_id: payment_transaction.accounting_bill_id, txn_type: 'Bill' }]
      )
    end
  end

  def accounting_bill_payment_private_note
    notes = payment_transactions.filter_map do |transaction|
      "#{transaction.shipment.pro}:\n#{transaction.notes}" if transaction.notes.present?
    end
    ["TMS Payment #{id}", "#{payment_method&.name} #{method_reference}".strip, *notes].join("\n")
  end

  def push_to_accounting
    PushPaymentToAccountingJob.perform_now(self) if Accounting.connected? && Accounting.supports?(:bill_payment)
  end
end
