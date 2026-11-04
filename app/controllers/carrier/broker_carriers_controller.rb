class Carrier::BrokerCarriersController < Carrier::CarrierController
  def index
    return redirect_to(carrier_broker_carrier_shipments_path(@broker_carriers.sole)) if @broker_carriers.one?

    stale?(@broker_carriers)
  end
end
