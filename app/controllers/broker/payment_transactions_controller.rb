# frozen_string_literal: true

class Broker::PaymentTransactionsController < Broker::BrokerController
  before_action :set_payment_transaction, only: %i[destroy edit show update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def due
    @q = current_user.broker.payment_transactions.due.includes(required_includes).ransack(params[:q])
    @q.sorts = 'due_on desc' if @q.sorts.blank?
    @pagy, @payment_transactions = pagy(@q.result(distinct: true))
  end

  def destroy
    @payment_transaction.destroy
    redirect_to broker_payments_path
  end

  def edit; end

  def import
    @payment_transaction = PaymentTransaction.new
  end

  def import_sample_csv
    due = 1.week.from_now.in_time_zone(current_user.broker.time_zone).to_date
    csv = <<~CSV
      pro,balance,due
      123-456,128.14,#{due}
    CSV

    send_data csv, disposition: 'attachment', type: 'text/csv', filename: 'Sample Statement.csv'
  end

  def index
    @payment_transactions = current_user.broker.payment_transactions.unpaid.order(:due_on)
  end

  def new
    @payment_transaction = PaymentTransaction.new
  end

  def create
    @payment_transaction = PaymentTransaction.new(payment_transaction_params.except(:csv))
    @payment_transaction.broker = current_user.broker

    if payment_transaction_params[:csv].blank?
      redirect_to [:broker, @payment_transaction] and return if @payment_transaction.save

      render :new and return
    end

    payment_transactions = []

    csv = payment_transaction_params[:csv].read.gsub(', ', ',')
    csv = CSV.parse(csv, headers: true)
    csv.each do |row|
      next if row.empty?

      balance_cents = row['balance'].to_f * 100
      due_on = nil
      invoice = nil

      if !row['due'].blank?
        begin
          due_on = Date.strptime(row['due'], '%Y-%m-%d')
        rescue Date::Error
          flash[:error] = 'Dates must be in the format YYYY-MM-DD'
          render :import and return
        end
      elsif !row['date'].blank?
        begin
          due_on = Date.strptime(row['due'], '%Y-%m-%d')
        rescue Date::Error
          flash[:error] = 'Dates must be in the format YYYY-MM-DD'
          render :import and return
        end

        due_on += @payment_transaction.broker_carrier.days_to_pay_after_invoice_date.days
      end

      invoice = row['invoice'] unless row['invoice'].blank?
      pro = row['pro']

      next if balance_cents.blank? || due_on.blank? || pro.blank?

      payment_transaction = PaymentTransaction
                            .where(broker: current_user.broker)
                            .where(broker_carrier: @payment_transaction.broker_carrier)
                            .where(pro:)
                            &.first
      payment_transaction = nil if payment_transaction&.payment&.paid?

      if payment_transaction.blank?
        payment_transaction = PaymentTransaction.new(
          broker_carrier: @payment_transaction.broker_carrier,
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
      flash[:error] = 'No new invoices found in statement'
      render :import and return
    end

    message_parts = ['Invoice'.pluralize(saved_payment_transactions_count)]
    message_parts << "(#{saved_payment_transactions_count} found altogether)" if saved_payment_transactions_count > 1
    message_parts += [
      'will be assigned',
      'payable'.pluralize(saved_payment_transactions_count),
      'shortly'
    ]

    flash[:success] = message_parts.join(' ')
    redirect_to due_broker_payment_transactions_path
  end

  def paid
    @q = current_user.broker.payment_transactions.paid.includes(required_includes).ransack(params[:q])
    @q.sorts = 'paid_on desc' if @q.sorts.blank?
    @pagy, @payment_transactions = pagy(@q.result(distinct: true))
  end

  def pay; end

  def show
    begin
      @payment_transaction.update_from_quickbooks_bill if @payment_transaction.quickbooks_bill_id.present?
    rescue StandardError
      # Rescuing everything to prevent UI problems
    end

    # TODO: Remove this requirement from view
    @q = PaymentTransaction.where(id: @payment_transaction.id).includes(:shipment).ransack({})
  end

  def update
    if @payment_transaction.update(payment_transaction_params)
      redirect_to broker_payment_transaction_path(@payment_transaction)
    else
      flash[:error] = 'Unable to update invoice'
      render :edit
    end
  end

  private

  def require_accounts_payable
    require_role 'accounts_payable'
  end

  def required_includes
    [
      :broker_carrier,
      :shipment,
      { broker_carrier: %i[broker_customer carrier] }
    ]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_payment_transaction
    @payment_transaction = PaymentTransaction.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def payment_transaction_params
    params.require(:payment_transaction).permit(:id, :approved_by_id, :additional_charge, :balance, :broker_carrier_id,
                                                :csv, :due_on, :notes, :paid, :pro, :shipment_load_id)
  end
end
