class Broker::Carriers::PaymentTransactionsController < Broker::Carriers::BaseController
  before_action :authorize_accounts_payable

  def index
    @q = @carrier.payment_transactions.includes(:shipment, broker_carrier: :carrier).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_on desc' if @q.sorts.blank?
    @pagy, @payment_transactions = pagy(@q.result)
  end
end
