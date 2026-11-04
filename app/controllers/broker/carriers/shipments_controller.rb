class Broker::Carriers::ShipmentsController < Broker::Carriers::BaseController
  def index
    @q = @carrier
         .shipments
         .includes(:applied_rate, :items, :receiver_address, :shipper_address, :tracking_carrier, broker_carrier: :carrier)
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end
end
