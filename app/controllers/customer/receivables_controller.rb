class Customer::ReceivablesController < Customer::CustomerController
  before_action :set_receivable, only: %i[show]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def index
    @q = current_user
         .companyable
         .receivables
         .includes(required_includes)
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def paid
    @q = current_user
         .companyable
         .receivables
         .paid
         .includes(required_includes)
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def show; end

  private

  def require_accounts_payable
    require_role('accounts_payable')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_receivable
    @receivable = current_user.companyable.receivables.find(params[:id])
  end

  def required_includes
    [:shipment, { broker_customer: :customer }]
  end
end
