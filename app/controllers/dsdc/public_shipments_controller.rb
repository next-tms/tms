class DSDC::PublicShipmentsController < DSDC::ShipmentsController
  skip_before_action :authenticate

  def show = stale?(@shipment, @shipment.items, @shipment.tracking_events, public: true)

  private

  def set_shipments = @shipments = Shipment.active.includes(INCLUDES)
end
