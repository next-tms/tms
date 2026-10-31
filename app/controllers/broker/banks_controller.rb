class Broker::BanksController < Broker::BrokerController
  before_action :set_bank, only: %i[activity show edit update]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def accounting
    authorize!(current_user, to: :root_show?, with: AccountingPolicy)

    @banks = Bank.order(:name, :account_number)

    @accounts = Accounting.supports?(:account) ? Accounting.record_class(:account).order(:name) : []
  end

  def activity
    @display_paid = ['0', nil].include?(params.dig(:q, :paid_on_null))

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
           }
         )
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'paid_on DESC' if @q.sorts.blank?
    @pagy, @payments = pagy(paid_or_pending_filter(@q))

    respond_to do |format|
      format.html
      format.csv do
        csv = ''.dup
        csv += "#{@payments.first.export_headers.join(',')}\n"
        csv += @payments.inject(''.dup) { |str, p| str << p.to_csv(false) }
        send_data(csv, filename: "#{@bank.pretty_name} Activity.csv")
      end
    end
  end

  def create
    @bank = Bank.new(bank_params)

    unless @bank.save
      render(:new)
      return
    end

    redirect_to([:broker, @bank])
  end

  def edit; end

  def index
    @q = Bank.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'name asc' if @q.sorts.blank?

    @pagy, @banks = pagy(@q.result)
  end

  def new
    @bank = Bank.new
  end

  def show = authorize!(@bank, to: :show?, with: BrokerPolicy)

  def update
    @bank.assign_attributes(bank_params)

    unless @bank.save
      flash[:danger] = t('.failure')
      render(:edit)
      return
    end

    redirect_to([:broker, Bank])
  end

  def update_accounting
    authorize!(current_user, to: :root_show?, with: AccountingPolicy)

    unless Bank.update(accounting_params.keys, accounting_params.values).all?(&:valid?)
      flash[:error] = t('.failure')
      redirect_to([:accounting, :broker, Bank])
      return
    end

    flash[:success] = t('.success')
    redirect_to([:accounting, :broker, Bank])
  end

  private

  # Query helpers
  def paid_or_pending_filter(query)
    @display_paid ? query.result.paid : query.result.unpaid
  end

  def require_accounts_payable
    require_role('accounts_payable')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_bank
    @bank = Bank.find_by(id: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bank_params
    params.expect(bank: %i[id account_number name accounting_account_id])
  end

  def accounting_params = params.expect(accounting: { banks: [%i[accounting_account_id kind]] }).require(:banks)
end
