class Carrier::ShipmentsController < Carrier::CarrierController
  before_action :set_broker_carrier

  def index
    @q = @broker_carrier.shipments.includes(:receiver_address, :shipper_address).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)

    stale?(@broker_carrier, @broker_carriers, @shipments, addresses)
  end

  private

  def addresses = Address.where(id: @shipments.pluck(:receiver_address_id) + @shipments.pluck(:shipper_address_id))
  def set_broker_carrier = @broker_carrier = @broker_carriers.find(params.expect(:broker_carrier_id))
end
