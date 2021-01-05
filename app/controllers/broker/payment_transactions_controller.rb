# frozen_string_literal: true

class Broker::PaymentTransactionsController < Broker::BrokerController
  before_action :set_payment_transaction, only: %i[destroy edit show update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def destroy
    @payment_transaction.destroy
    redirect_to broker_payments_path
  end

  def index
    @payment_transactions = current_user.broker.payment_transactions.unpaid.order(:due_on)
  end

  def import
    @payment_transaction = PaymentTransaction.new
  end

  def new
    @payment_transaction = PaymentTransaction.new
  end

  def create
    if payment_transaction_params[:csv].blank?
      @payment_transaction = PaymentTransaction.new(payment_transaction_params)
      @payment_transaction.broker = current_user.broker
      if @payment_transaction.save
        redirect_to [:broker, @payment_transaction] and return
      else
        render :new and return
      end
    else
      broker_id = current_user.broker.id
      broker_carrier_id = payment_transaction_params[:broker_carrier_id]
      created_by_id = current_user.id

      csv = payment_transaction_params[:csv].gsub(', ', ',')
      csv = CSV.parse(csv, headers: true)
      csv.each do |row|
        next if row.empty?

        balance_cents = row.dig('balance').to_f * 100
        due_on = nil
        invoice = nil

        if !row.dig('due').blank?
          due_on = Date.strptime(row.dig('due'), '%m/%d/%y')
        elsif !row.dig('date').blank?
          due_on = Date.strptime(row.dig('date'), '%m/%d/%y') + BrokerCarrier.find(broker_carrier_id).days_to_pay_after_invoice_date.days
        end

        invoice = row.dig('invoice') unless row.dig('invoice').blank?

        pro = row.dig('pro')

        next if balance_cents.blank? || due_on.blank? || pro.blank?
        old_payment_transaction = PaymentTransaction.where(broker_id: broker_id).where(pro: pro).where(broker_carrier_id: broker_carrier_id)
        if old_payment_transaction.blank?
          PaymentTransaction.create(
            broker_id: broker_id,
            broker_carrier_id: broker_carrier_id,
            balance_cents: balance_cents,
            created_by_id: created_by_id,
            due_on: due_on,
            invoice: invoice,
            pro: pro
          )
        else
          old_payment_transaction = old_payment_transaction.first
          if old_payment_transaction.payment.paid_on.blank?
            old_payment_transaction.balance_cents = balance_cents
            old_payment_transaction.due_on = due_on
            old_payment_transaction.save
          end
        end
      end

      flash[:notice] = 'Updated database from report'
      redirect_to broker_payments_path and return
    end
  end

  def edit; end

  def update
    if !@payment_transaction.update(payment_transaction_params)
      flash[:error] = 'Unable to update invoice'
      render :edit
    else
      redirect_to broker_payment_transaction_path(@payment_transaction)
    end
  end

  def pay; end

  def show; end

  private

  def require_accounts_payable
    require_role 'accounts_payable'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_payment_transaction
    @payment_transaction = PaymentTransaction.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def payment_transaction_params
    params.require(:payment_transaction).permit(:id, :approved_by_id, :additional_charge, :balance, :broker_carrier_id, :csv, :due_on, :notes, :paid, :pro, :shipment_load_id)
  end
end
