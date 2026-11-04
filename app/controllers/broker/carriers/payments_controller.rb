class Broker::Carriers::PaymentsController < Broker::Carriers::BaseController
  before_action :authorize_accounts_payable

  def index
    @q = @carrier
         .payments
         .includes(:payment_transactions, broker_carrier: [:carrier, { broker_customer: :customer }])
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_on desc' if @q.sorts.blank?
    @pagy, @payments = pagy(@q.result)
  end
end
