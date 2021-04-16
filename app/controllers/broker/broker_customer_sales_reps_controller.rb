# frozen_string_literal: true

class Broker::BrokerCustomerSalesRepsController < Broker::BrokerController
  before_action :set_broker_customer_sales_rep, only: %i[broker_customers destroy edit show update]
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @broker_customer_sales_reps = User.where(
      id: [
        BrokerCustomerSalesRep.joins(:user).where(
          user_id: [
            current_user.broker.users.pluck(:id)
          ]).pluck(:user_id)
        ]
      ).distinct.order(:first_name)
  end

  def broker_customers; end

  private

  # Use callbacks to share common setup or constraints between actions.
  def require_admin
    require_role 'admin'
  end

  def set_broker_customer_sales_rep
    @broker_customer_sales_rep = current_user.broker.users.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def set_user_params
    params.require(:user).permit(:id)
  end
end
