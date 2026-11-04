class Broker::Carriers::BrokerCarriers::BaseController < Broker::Carriers::BaseController
  before_action :set_broker_carrier

  private

  def set_broker_carrier = @broker_carrier = @carrier.broker_carriers.find(params.expect(:broker_carrier_id))
end
