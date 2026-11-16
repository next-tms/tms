class Freightview::ShipmentsController < Freightview::ApplicationController
  INCLUDES = [
    :applied_rate,
    :receiver_address,
    :shipper_address,
    :tracking_carrier,
    {
      broker_accessorials: :accessorial,
      broker_carrier: :carrier,
      items: :packaging
    }
  ].freeze

  def show
    @shipment = authorized_scope(Shipment.includes(INCLUDES)).find_by!(load_id: params.expect(:shipment_id))
    authorize!(@shipment, to: :view?)

    stale?(
      @shipment,
      @shipment.applied_rate,
      @shipment.broker_carrier,
      @shipment.broker_carrier&.carrier,
      @shipment.items,
      @shipment.receiver_address,
      @shipment.shipper_address,
      @shipment.tracking_carrier
    )
  end
end
