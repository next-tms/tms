class Broker::PaymentTransactionsController < Broker::BrokerController
  before_action :set_payment_transaction, only: %i[destroy edit show update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def due
    @q = PaymentTransaction.due.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_on asc' if @q.sorts.blank?
    @pagy, @payment_transactions = pagy(@q.result(distinct: true))
  end

  def destroy
    @payment_transaction.destroy
    redirect_to(broker_payments_path)
  end

  def edit; end

  def import
    @payment_transaction = PaymentTransaction.new
  end

  def import_sample_csv
    now = DateTime.current.in_time_zone(Setting.time_zone).to_date
    due = now + 2.weeks

    csv = <<~CSV
      pro,load,balance,date,due
      123-456,12345,128.14,#{now},#{due}
    CSV

    send_data(csv, disposition: 'attachment', type: 'text/csv', filename: 'Sample Statement.csv')
  end

  def index
    @payment_transactions = PaymentTransaction.unpaid.order(:due_on)
  end

  def new
    @payment_transaction = PaymentTransaction.new
  end

  def create
    @payment_transaction = PaymentTransaction.new(payment_transaction_params.except(:csv))

    if payment_transaction_params[:csv].blank?
      redirect_to([ :broker, @payment_transaction ]) and return if @payment_transaction.save

      render(:new) and return
    else
      csv = payment_transaction_params[:csv].read.gsub(', ', ',')
      service = ProcessPaymentTransactionCsvService
                .new(csv:, broker_carrier: @payment_transaction.broker_carrier, current_user:)
                .call

      flash[service.status] = service.message
      render(:import) and return if service.status == :error

      redirect_to(due_broker_payment_transactions_path)
    end
  end

  def paid
    @q = PaymentTransaction.paid.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'paid_on desc' if @q.sorts.blank?
    @pagy, @payment_transactions = pagy(@q.result(distinct: true))
  end

  def pay; end

  def show
    begin
      @payment_transaction.update_from_accounting_bill if @payment_transaction.accounting_bill_id.present?
    rescue StandardError => exception
      Sentry.capture_exception(exception)
    end

    # TODO: Remove this requirement from view
    @q = PaymentTransaction
         .where(id: @payment_transaction.id)
         .includes(:shipment)
         .ransack({}, auth_object: current_user)
  end

  def update
    if @payment_transaction.update(payment_transaction_params)
      redirect_to(broker_payment_transaction_path(@payment_transaction))
    else
      flash[:error] = 'Unable to update invoice'
      render(:edit)
    end
  end

  private

  def require_accounts_payable
    require_role('accounts_payable')
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
    params
    .require(:payment_transaction)
    .permit(
      :id,
      :additional_charge,
      :approved_by_id,
      :balance,
      :broker_carrier_id,
      :csv,
      :due_on,
      :notes,
      :paid,
      :pro,
      :shipment_load_id,
    )
  end
end
