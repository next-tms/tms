class Broker::Shipments::BaseController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_shipments
  before_action :set_shipment

  private

  def set_shipment = @shipment = @shipments.find_by!(load_id: params.expect(:shipment_load_id))
  def set_shipments = @shipments = authorized_scope(Shipment.all)
end
