class Broker::Carriers::BrokerCarriers::ShipmentsController < Broker::Carriers::BrokerCarriers::BaseController
  def index
    authorize!(@broker_carrier, to: :show?, with: BrokerPolicy)

    @q = @broker_carrier
         .shipments
         .includes(:applied_rate, :items, :receiver_address, :shipper_address, :tracking_carrier, broker_carrier: :carrier)
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end
end
