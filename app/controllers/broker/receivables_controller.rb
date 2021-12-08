# frozen_string_literal: true

class Broker::ReceivablesController < Broker::BrokerController
  before_action :set_receivable, only: %i[destroy edit pay rebuild show update]
  before_action :authenticate_user!
  before_action :require_accounts_receivable

  def destroy
    @receivable.destroy
    redirect_to broker_receivables_path
  end

  def index
    @display_paid = ['0', nil].include?(params.dig(:q, :paid_at_null))

    @q = current_user.broker.receivables.includes(required_includes).ransack(params[:q])
    @q.sorts = 'due_by asc' if @q.sorts.blank?
    @pagy, @receivables = pagy(paid_or_pending_filter(@q))
  end

  def paid
    @q = Receivable.paid.includes(required_includes).ransack(params[:q])
    @pagy, @receivables = pagy(@q.result(distinct: true))
  end

  def new
    @receivable = Receivable.new
  end

  def rebuild
    @receivable.build_from_shipment(@receivable.shipment)
    @receivable.save

    redirect_to broker_receivable_path(@receivable)
  end

  def create; end

  def edit; end

  def update
    if !@receivable.update(receivable_params)
      flash[:error] = 'Unable to update receivable'
      render :edit
    else
      redirect_to broker_receivable_path(@receivable)
    end
  end

  def show; end

  private

  def require_accounts_receivable
    require_role 'accounts_receivable'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_receivable
    @receivable = Receivable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def receivable_params
  end

  # Query helpers
  def paid_or_pending_filter(q)
    @display_paid ? q.result.paid : q.result.unpaid
  end

  def required_includes
    [ :shipment, broker_customer: :customer ]
  end
end
