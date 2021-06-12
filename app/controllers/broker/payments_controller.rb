# frozen_string_literal: true

class Broker::PaymentsController < Broker::BrokerController
  before_action :set_payment, only: %i[destroy edit pay show update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def destroy
    @payment.destroy
    redirect_to broker_payments_path
  end

  def import_legacy
    @payment = Payment.new
    @payment.paid_on = Date.current
  end

  def index
    @display_paid = ['0', nil].include?(params.dig(:q, :paid_on_null))

    @q = Payment.includes(required_includes).ransack(params[:q])
    @pagy, @payments = pagy(paid_or_pending_filter(@q))
  end

  def paid
    @q = Payment.paid.includes(required_includes).ransack(params[:q])
    @pagy, @payments = pagy(@q.result(distinct: true))
  end

  def new
    @payment = Payment.new
  end

  def create
    if payment_params[:legacy_csv].blank?
      @payment = Payment.new(payment_params)
      @payment.broker = BrokerCarrier.find(payment_params[:broker_carrier_id]).broker
      @payment.created_by = current_user

      if @payment.save
        redirect_to [:broker, @payment]
      else
        render :new
      end
    else
      broker_id = current_user.broker.id
      broker_carrier_id = payment_params[:broker_carrier_id]
      created_by_id = current_user.id

      payment_transactions = []
      csv = payment_params[:legacy_csv].gsub(', ', ',')
      csv = CSV.parse(csv, headers: true)
      csv.each do |row|
        next if row.empty?

        paid_cents = row.dig('paid').to_f * 100
        invoice = nil
        legacy_load_id = nil
        notes = nil

        invoice = row.dig('invoice') unless row.dig('invoice').blank?

        legacy_load_id = row.dig('legacy load')
        notes = row.dig('notes')
        pro = row.dig('pro')

        next if paid_cents.blank? || legacy_load_id.blank? || pro.blank?

        payment_transaction = PaymentTransaction.create(broker: BrokerCarrier.find(payment_params[:broker_carrier_id]).broker, broker_carrier: BrokerCarrier.find(payment_params[:broker_carrier_id]), created_by: current_user, legacy_load_id: legacy_load_id, notes: notes, paid_cents: paid_cents, pro: pro)
        payment_transactions << payment_transaction
      end

      @payment = Payment.new

      @payment.broker = BrokerCarrier.find(payment_params[:broker_carrier_id]).broker
      @payment.broker_carrier = BrokerCarrier.find(payment_params[:broker_carrier_id])
      @payment.created_by = current_user
      @payment.paid_on = payment_params[:paid_on]
      @payment.method_reference = payment_params[:method_reference]
      @payment.payment_transactions = payment_transactions

      if @payment.save
        redirect_to [:broker, @payment]
      else
        render :import_legacy
      end
    end
  end

  def edit; end

  def update
    if !@payment.update(payment_params)
      flash[:error] = 'Unable to update payment'
      render :edit
    else
      redirect_to broker_payment_path(@payment)
    end
  end

  def pay
    @payment.paid_on = Date.current
  end

  def show; end

  private

  def require_accounts_payable
    require_role 'accounts_payable'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_payment
    @payment = Payment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def payment_params
    params.require(:payment).permit(:id, :approved_by_id, :bank_id, :broker_carrier_id, :legacy_csv, :due_on, :legacy_csv, :method_reference, :payment_method_id, :paid_on, payment_transactions_attributes: %i[_destroy id additional_charge balance invoice legacy_load_id notes paid pro shipment_load_id])
  end

  # Query helpers
  def paid_or_pending_filter(q)
    @display_paid ? q.result.paid : q.result.unpaid
  end

  def required_includes
    [ :bank, :broker_carrier, { broker_carrier: :carrier } ]
  end
end
