# frozen_string_literal: true

class Broker::BrokerCustomerSalesRepsController < Broker::BrokerController
  before_action :set_broker_customer_sales_rep, only: %i[commissions destroy edit show update]
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @broker_customer_sales_reps = User.where(id: current_user.broker.broker_customer_sales_reps.pluck(:user_id)).order(:first_name)
  end

  def commissions
    @q = @broker_customer_sales_rep.commissions.includes(required_includes).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @commissions = pagy(@q.result)
  end

  private

  def require_admin
    require_role 'admin'
  end

  def set_broker_customer_sales_rep
    @broker_customer_sales_rep = current_user.broker.users.find(params[:id])
  end

  def set_user_params
    params.require(:user).permit(:id)
  end

  # Query helpers
  def required_includes
    [
      :shipment,
      { shipment: { broker_customer: :customer } }
    ]
  end
end
