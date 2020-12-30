# frozen_string_literal: true

class TrackingController < ApplicationController
  before_action :set_load_id

  def show
    redirect_to root_path and return unless @website

    @shipment = Shipment.none
    unless @load_id.blank?
      @shipment = @website.broker.shipments.where(load_id: @load_id)
      @shipment = @shipment.first unless @shipment.blank?
    end
    if @shipment.blank? && !@load_id.blank?
      @shipment = @website.broker.shipments.where(pro: @load_id)
      @shipment = @shipment.first unless @shipment.blank?
    end
    if @shipment.blank? && !@load_id.blank?
      @shipment = @website.broker.shipments.where(bol: @load_id)
      @shipment = @shipment.first unless @shipment.blank?
    end

    @shipment.update_tracking_events unless @shipment.blank?
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_load_id
    @load_id = params[:load_id]
    @load_id = @load_id.to_s.gsub(/[[:space:]]/, '').to_i unless @load_id.blank?
  end
end
