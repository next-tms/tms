# frozen_string_literal: true

class Api::V1::Broker::ShipmentsController < Api::ApplicationController
  before_action do
    self.namespace_for_serializer = 'Broker'
  end

  def index
    shipments = current_user.broker.shipments
    render json: shipments, status: :ok
  end

  def show
    shipment = Shipment.find_by_load_id(params[:load_id])

    render json: shipment, status: :ok and return if shipment.broker == current_user.broker

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
