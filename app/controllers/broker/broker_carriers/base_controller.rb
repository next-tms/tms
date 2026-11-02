class Broker::BrokerCarriers::BaseController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_broker_carrier

  private

  def set_broker_carrier = @broker_carrier = BrokerCarrier.find(params.expect(:broker_carrier_id))
end
