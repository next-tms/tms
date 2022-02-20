# frozen_string_literal: true

class Customer::ReceivablesController < Customer::CustomerController
  before_action :set_receivable, only: %i[destroy edit pay show]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def destroy
    @receivable.destroy
    redirect_to broker_receivables_path
  end

  def index
    @q = current_user.broker_customer.receivables.includes(required_includes).ransack(params[:q])
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def paid
    @q = current_user.broker_customer.receivables.paid.includes(required_includes).ransack(params[:q])
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def create; end

  def edit; end

  def update
    @receivable.assign_attributes(receivable_params)
    @receivable.updated_by = current_user

    @receivable.authorized_by = current_user unless receivable_params[:authorized_at].blank?
    @receivable.sent_by = current_user unless receivable_params[:sent_at].blank?

    if @receivable.save
      if current_user.broker_customer.intuit_account&.connected?
        PushReceivableToQuickbooksJob.perform_now(receivable: @receivable)
      end

      redirect_to broker_receivable_path(@receivable) and return
    end

    flash[:error] = "Unable to update invoice: #{@receivable.errors.full_messages.join('<br>').html_safe}"
    render :show
  end

  def show; end

  private

  def require_accounts_payable
    require_role 'accounts_payable'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_receivable
    @receivable = current_user.broker_customer.receivables.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def receivable_params
    params.require(:receivable).permit(:id)
  end

  def required_includes
    [:shipment, { broker_customer: :customer }]
  end
end
