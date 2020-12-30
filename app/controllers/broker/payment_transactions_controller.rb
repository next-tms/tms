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

      payment_transactions = []
      csv = payment_transaction_params[:csv].gsub(', ', ',')
      csv = CSV.parse(csv, headers: true)
      csv.each do |row|
        next if row.empty?

        balance_cents = row.dig('balance').to_f * 100
        due_on = nil
        invoice = nil

        if !row.dig('due').blank?
          due_on = Date.strptime(row.dig('due'), '%m/%d/%Y')
        elsif !row.dig('date').blank?
          due_on = Date.strptime(row.dig('date'), '%m/%d/%Y') + BrokerCarrier.find(broker_carrier_id).days_to_pay_after_invoice_date.days
        end

        invoice = row.dig('invoice') unless row.dig('invoice').blank?

        pro = row.dig('pro')

        next if balance_cents.blank? || due_on.blank? || pro.blank?

        old_payment_transaction = PaymentTransaction.where(broker_id: broker_id).where(pro: pro).where(broker_carrier_id: broker_carrier_id)
        if old_payment_transaction.blank?
          payment_transaction = {
            broker_id: broker_id,
            broker_carrier_id: broker_carrier_id,
            balance_cents: balance_cents,
            created_by_id: created_by_id,
            due_on: due_on,
            invoice: invoice,
            pro: pro
          }
          payment_transactions << payment_transaction
        else
          old_payment_transaction = old_payment_transaction.first
          if old_payment_transaction.payment.paid_on.blank?
            old_payment_transaction.balance_cents = balance_cents
            old_payment_transaction.due_on = due_on
            old_payment_transaction.set_week
            old_payment_transaction.set_payment
            old_payment_transaction.set_shipment
            old_payment_transaction.save
          end
        end
      end

      payment_transaction_imports = PaymentTransaction.import(payment_transactions)
      if payment_transaction_imports.num_inserts != 0
        # import doesnt' support callbacks on save
        PaymentTransaction.where(id: payment_transaction_imports.ids).each do |payment_transaction|
          payment_transaction.set_week
          payment_transaction.set_payment
          payment_transaction.set_shipment
          payment_transaction.save
        end
        flash[:notice] = "Imported #{payment_transaction_imports.num_inserts} invoices"
        redirect_to broker_payments_path and return
      else
        @payment_transaction = PaymentTransaction.new
        flash[:error] = 'No new invoices found'
        render :import and return
      end
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
