class Broker::PaymentsController < Broker::BrokerController
  before_action :set_payment, only: %i[edit pay show update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def due
    @q = Payment.due.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_on asc' if @q.sorts.blank?
    @pagy, @payments = pagy(@q.result(distinct: true))
  end

  def paid
    @q = Payment.paid.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'paid_on desc' if @q.sorts.blank?
    @pagy, @payments = pagy(@q.result(distinct: true))
  end

  def edit; end

  def update
    redirect_to(broker_payment_path(@payment)) and return if @payment.update(payment_params)

    flash[:error] = 'Unable to update payment'
    render(:edit)
  end

  def pay
    @banks = Bank.order(:name)
    @payment_methods = PaymentMethod.all.order(:name)
    selected_bank = @payment.bank || @banks.first

    @selected_payment_method = selected_bank.applicable_payment_method
    @bank_payment_method_ids = @banks.map { |bank| bank.applicable_payment_method.id }.join
  end

  def show
    @q = @payment.payment_transactions.includes(:shipment).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_on desc' if @q.sorts.blank?

    @pagy, @payment_transactions = pagy(@q.result)
  end

  def new
    @payment = Payment.new
  end

  def create
    broker_carrier = BrokerCarrier.find(params[:broker_carrier_id])
    cutoff_date = params[:cutoff_date]
    payment_transactions = broker_carrier
                           .payment_transactions
                           .where(payment: nil)
                           .where('due_on <= ?', cutoff_date.to_date)

    @payment = Payment.new(broker_carrier:, due_on: cutoff_date, payment_transactions:)

    if @payment.save
      flash[:success] = "Successfully Created new Payment for #{broker_carrier.broker_customer_specific_name}"
      redirect_to(broker_payment_path(@payment))
    else
      render(:new)
    end
  end

  def due_payment_transactions
    broker_carrier = BrokerCarrier.find(params[:broker_carrier_id])
    cutoff_date = params[:cutoff_date]
    payment_transactions = broker_carrier
                           .payment_transactions
                           .where(payment: nil)
                           .where('due_on <= ?', cutoff_date.to_date)

    render(json: {
      payment_transactions_count: payment_transactions.count,
      broker_carrier_name: broker_carrier.broker_customer_specific_name,
      date: cutoff_date.to_date.strftime('%b %e %Y')
    })
  end

  private

  def require_accounts_payable
    require_role('accounts_payable')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_payment
    @payment = Payment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def payment_params
    params
    .require(:payment)
    .permit(
      :id,
      :approved_by_id,
      :bank_id,
      :broker_carrier_id,
      :due_on,
      :method_reference,
      :paid_on,
      :payment_method_id,
      payment_transactions_attributes: %i[
                                         _destroy
                                         id
                                         additional_charge
                                         balance
                                         invoice
                                         notes
                                         paid
                                         pro
                                         shipment_load_id
                                       ],
    )
  end

  def required_includes
    [
      :broker_carrier,
      :payment_transactions,
      { broker_carrier: %i[broker_customer carrier] }
    ]
  end
end
