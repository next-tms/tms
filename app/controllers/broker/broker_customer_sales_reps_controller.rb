# frozen_string_literal: true

class Broker::BrokerCustomerSalesRepsController < Broker::BrokerController
  before_action :set_broker_customer_sales_rep, only: %i[show]
  before_action :authenticate_user!
  before_action :require_admin, except: %i[show]

  def index
    @q = User
         .where(id: BrokerCustomerSalesRep.all.pluck(:user_id))
         .includes(:companyable)
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'first_name asc' if @q.sorts.blank?

    @pagy, @broker_customer_sales_reps = pagy(@q.result)
  end

  def show
    require_admin unless @broker_customer_sales_rep.id == current_user.id

    @q = @broker_customer_sales_rep
         .commissions
         .includes(required_includes)
         .ransack(
           params[:q],
           auth_object: current_user,
         )
    @q.sorts = 'shipment_load_id desc' if @q.sorts.blank?

    @pagy, @commissions = pagy(@q.result)
  end

  private

  def require_admin
    require_role('admin')
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
