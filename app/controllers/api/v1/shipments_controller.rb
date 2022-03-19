# frozen_string_literal: true

class Api::V1::ShipmentsController < Api::ApplicationController
  skip_before_action :authenticate_request

  def tracking_events
    shipment = Shipment.find_by_load_id(params[:load_id])

    render json: shipment.tracking_events.order(:at), status: :ok
  end
end
