# frozen_string_literal: true

class ProcessPaymentTransactionCsvService
  attr_accessor :csv, :broker_carrier, :current_user, :message, :status, :payment_transactions

  def initialize(csv:, broker_carrier:, current_user:)
    @csv = CSV.parse(csv, headers: true, skip_blanks: true, skip_lines: /^(?:,\s*)+$/)
    @broker_carrier = broker_carrier
    @current_user = current_user

    @message = nil
    @status = :error
    @payment_transactions = []
  end

  def call
    csv.each do |row|
      balance_cents = parse_balance(row['balance'])

      if balance_cents.blank?
        @message = "Unable to extract balance amount (\"balance\") from row: #{row}"
        return self
      end

      due_on = parse_date(row['due']) unless row['due'].blank?
      due_on ||= parse_date(row['date']) unless row['date'].blank?

      if due_on.blank?
        @message = "Unable to extract dates (\"date\") from row: #{row}, dates must be in the format YYYY-MM-DD"
        return self
      end

      invoice = row['invoice'] unless row['invoice'].blank?

      pro = row['pro']
      pro ||= Shipment.find_by_load_id(row['load'])&.pro unless row['load'].blank?

      next if balance_cents.blank? || due_on.blank? || pro.blank?

      payment_transaction = PaymentTransaction
                            .where(broker: current_user.broker)
                            .where(broker_carrier:)
                            .where(pro:)
                            &.first
      payment_transaction = nil if payment_transaction&.payment&.paid?

      if payment_transaction.blank?
        payment_transaction = PaymentTransaction.new(
          broker_carrier:,
          created_by: current_user,
          invoice:,
          pro:
        )
      end

      payment_transaction.assign_attributes(balance_cents:, due_on:)
      payment_transactions << payment_transaction
    end

    saved_payment_transactions_count = payment_transactions.map(&:save).count(true)

    if saved_payment_transactions_count.zero?
      @message = 'No new invoices found in statement'
      return self
    end

    @message = build_success_message(saved_payment_transactions_count)
    @status = :success

    self
  end

  private

  def parse_balance(balance)
    case balance[-3]
    when '.'
      (Float(balance.gsub(',', '')) * 100).to_i
    when ','
      (Float(balance.gsub('.', '')) * 100).to_i
    else
      (Float(balance) * 100).to_i
    end
  rescue ArgumentError
    nil
  end

  def parse_date(date_str, date_type)
    date = Date.strptime(date_str, '%Y-%m-%d')
    return date if date_type == :due

    date += broker_carrier.days_to_pay_after_invoice_date.days
    date
  rescue Date::Error
    nil
  end

  def build_success_message(saved_payment_transactions_count)
    message_parts = [ 'Invoice'.pluralize(saved_payment_transactions_count) ]
    message_parts << "(#{saved_payment_transactions_count} found altogether)" if saved_payment_transactions_count > 1
    message_parts += [
      'will be assigned',
      'payable'.pluralize(saved_payment_transactions_count),
      'shortly'
    ]

    message_parts.join(' ')
  end
end
