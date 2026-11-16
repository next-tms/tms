class BrokerWare::TrackingController < BrokerWare::ApplicationController
  INCLUDES = [:receiver_address, :shipper_address, :tracking_carrier, { broker_carrier: :carrier }].freeze

  def show
    @shipment = authorized_scope(Shipment.includes(INCLUDES)).find_by!(load_id: params[:loadid].presence || params.require(:load_id))
    authorize!(@shipment, to: :view?)

    stale?(@shipment, @shipment.broker_carrier, @shipment.carrier, @shipment.receiver_address, @shipment.shipper_address)
  end
end
