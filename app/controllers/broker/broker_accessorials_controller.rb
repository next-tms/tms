class Broker::BrokerAccessorialsController < Broker::BrokerController
  before_action :set_broker_accessorial, only: %i[show edit update]
  before_action :authenticate_user!

  def index
    @broker_accessorials = BrokerAccessorial.order(:name)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_accessorial
    @broker_accessorial = BrokerCustomer.find(params[:id])
  end
end
