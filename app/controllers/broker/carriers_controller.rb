class Broker::CarriersController < Broker::BrokerController
  include BrokerCarrierParameters

  before_action :authenticate_user!
  before_action -> { authorize!(current_user, to: :show?, with: BrokerPolicy) }
  before_action :set_carrier, only: %i[show]

  def create
    @broker_carrier = BrokerCarrier.new(broker_carrier_params(:carrier_id))
    @broker_carrier.ignore_bol_requires_tracking_number = Setting.ignore_broker_carrier_bol_requires_tracking_number(false)

    unless @broker_carrier.save
      render(:new, status: :unprocessable_content)
      return
    end

    redirect_to([:broker, @broker_carrier.carrier, @broker_carrier])
  end

  def index
    @q = Carrier.where(id: BrokerCarrier.select(:carrier_id)).includes(:broker_carriers).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'name asc' if @q.sorts.blank?
    @pagy, @carriers = pagy(@q.result)
  end

  def new = @broker_carrier = BrokerCarrier.new(check_mailing_address: Address.new)
  def show = @broker_carriers = @carrier.broker_carriers.includes(broker_customer: :customer)

  private

  def set_carrier = @carrier = Carrier.where(id: BrokerCarrier.select(:carrier_id)).find(params.expect(:id))
end
