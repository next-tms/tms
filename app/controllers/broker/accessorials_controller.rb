class Broker::AccessorialsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_accessorials

  def index
    @q = @accessorials.includes(broker_customer: :customer).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'name asc' if @q.sorts.blank?

    @pagy, @accessorials = pagy(@q.result)
    customers = Customer.where(id: BrokerCustomer.where(id: @accessorials.select(:broker_customer_id)).select(:customer_id))

    respond_to { |format| format.html { stale?(@accessorials, customers) } }
  end

  private

  def set_accessorials = @accessorials = authorized_scope(Accessorial.all)
end
