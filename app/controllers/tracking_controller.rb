class TrackingController < ApplicationController
  before_action :set_load_id

  def show
    @shipment = if @load_id.present?
                  Shipment.active.find_by(load_id: @load_id) ||
                    Shipment.active.find_by(pro: @load_id) ||
                    Shipment.active.find_by(bol: @load_id)
                end

    @shipment.presence&.update_tracking_events
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_load_id
    @load_id = params[:load_id]

    return if @load_id.blank?

    @load_id = @load_id.to_s.gsub(/[[:space:]]/, '').to_i
    @load_id = '' if @load_id.zero?
  end
end
