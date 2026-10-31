class Broker::ReceivablesController < Broker::BrokerController
  before_action :set_receivable, only: %i[destroy edit rebuild show update]
  before_action :authenticate_user!
  before_action :require_accounts_receivable

  def destroy
    @receivable.destroy
    redirect_to(broker_receivables_path)
  end

  def index
    @q = Receivable.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def authorized
    @q = Receivable.authorized.not_invoiced.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def invoiced
    @q = Receivable.invoiced.unpaid.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def paid
    @q = Receivable.paid.includes([:shipment, { broker_customer: :customer }, :authorized_by]).ransack(params[:q],
                                                                                                       auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def unauthorized
    @q = Receivable.unauthorized.not_invoiced.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def new
    @receivable = Receivable.new
  end

  def rebuild
    @receivable.build_from_shipment(@receivable.shipment)
    @receivable.updated_by = current_user
    @receivable.save

    redirect_to(broker_receivable_path(@receivable))
  end

  def create; end

  def edit; end

  def update
    @receivable.assign_attributes(receivable_params)
    @receivable.updated_by = current_user

    @receivable.authorized_by = current_user if receivable_params[:authorized_at].present?
    @receivable.sent_by = current_user if receivable_params[:sent_at].present?

    unless @receivable.save
      flash[:error] = "Unable to update invoice: #{@receivable.errors.full_messages.to_sentence}"
      render(:show)
      return
    end

    PushReceivableToAccountingJob.perform_now(receivable: @receivable) if Accounting.connected?
    redirect_to([:broker, @receivable])
  end

  def show
    #    if Accounting.connected? && @receivable.authorized_by_id.blank?
    #      @receivable.accounting_invoice
    #    end
  end

  private

  def require_accounts_receivable
    require_role('accounts_receivable')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_receivable
    @receivable = Receivable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def receivable_params = params.expect(receivable: %i[id authorized_at invoiced sent_at])

  def required_includes
    [{ shipment: { carrier_pod_attachment: :blob } }, { broker_customer: :customer }, :authorized_by]
  end
end
