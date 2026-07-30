class Broker::BanksController < Broker::BrokerController
  before_action :set_bank, only: %i[activity show edit update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def accounting
    authorize!(current_user, to: :root_show?, with: AccountingPolicy)

    @banks = current_user
             .broker
             .banks
             .order(:name, :account_number)

    @accounts = Accounting.supports?(:account) ? Accounting.record_class(:account).order(:name) : []
  end

  def activity
    @display_paid = [ '0', nil ].include?(params.dig(:q, :paid_on_null))

    @q = @bank
         .payments
         .paid
         .includes(
           :payment_transactions,
           {
             broker_carrier: [
                               :carrier,
                               { broker_customer: :customer }
                             ]
           },
         )
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'paid_on DESC' if @q.sorts.blank?
    @pagy, @payments = pagy(paid_or_pending_filter(@q))

    respond_to do |format|
      format.html
      format.csv do
        csv = ''.dup
        csv += "#{@payments.first.export_headers.join(",")}\n"
        csv += @payments.inject(''.dup) { |str, p| str << p.to_csv(false) }
        send_data(csv, filename: "#{@bank.pretty_name} Activity.csv")
      end
    end
  end

  def create
    @bank = Bank.new(bank_params)
    @bank.broker = current_user.broker
    if @bank.save
      redirect_to([ :broker, @bank ])
    else
      render(:new)
    end
  end

  def edit; end

  def index
    @q = current_user.broker.banks.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'name asc' if @q.sorts.blank?

    @pagy, @banks = pagy(@q.result)
  end

  def new
    @bank = Bank.new
  end

  def show
    authorize!(@bank, to: :show?, with: BrokerPolicy)
  end

  def update
    @bank.assign_attributes(bank_params)

    redirect_to(broker_banks_path) && return if @bank.save

    flash[:danger] = 'Unable to update bank'
    render(:edit)
  end

  def update_accounting
    authorize!(current_user, to: :root_show?, with: AccountingPolicy)

    broker = current_user.broker
    broker.assign_attributes(broker_params)

    if broker.save
      flash[:success] = 'Accounting accounts updated'
      redirect_to(accounting_broker_banks_path) && return
    end

    @accounts = Accounting.supports?(:account) ? Accounting.record_class(:account).order(:name) : []

    render(:accounting)
  end

  private

  # Query helpers
  def paid_or_pending_filter(q)
    @display_paid ? q.result.paid : q.result.unpaid
  end

  def require_accounts_payable
    require_role('accounts_payable')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_bank
    @bank = current_user.broker&.banks&.where(id: params[:id])&.first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bank_params
    params.require(:bank).permit(
      :id,
      :account_number,
      :name,
      :accounting_account_id,
    )
  end

  def broker_params
    params.require(:broker).permit(
      :id,
      banks_attributes: %i[id kind accounting_account_id],
    )
  end
end
