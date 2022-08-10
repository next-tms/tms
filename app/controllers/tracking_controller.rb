# frozen_string_literal: true

class TrackingController < ApplicationController
  before_action :set_load_id

  def show
    redirect_to root_path and return unless @website

    @shipment = Shipment.none
    unless @load_id.blank?
      @shipment = @website.broker.shipments.active.where(load_id: @load_id)
      @shipment = @shipment.first unless @shipment.blank?
    end
    if @shipment.blank? && !@load_id.blank?
      @shipment = @website.broker.shipments.active.where(pro: @load_id)
      @shipment = @shipment.first unless @shipment.blank?
    end
    if @shipment.blank? && !@load_id.blank?
      @shipment = @website.broker.shipments.active.where(bol: @load_id)
      @shipment = @shipment.first unless @shipment.blank?
    end

    @shipment.update_tracking_events unless @shipment.blank?

    respond_to do |format|
      format.html
      format.rss do
        render :no_content and return if @shipment.blank?

        render plain: rss, content_type: 'application/rss+xml'
      end
    end
  end

  private

  def rss
    desc = ["Tracking events for Load #{@shipment.load_id} (#{@website.broker.name})"]
    desc << "\n\nNotes:\n#{@shipment.public_notes}" unless @shipment.public_notes.blank?

    rss = RSScreator.new
    rss.title = "Load #{@shipment.load_id}"
    rss.desc = desc.join

    @shipment.tracking_events.includes(:event).find_each do |tracking_event|
      rss.add(
        {
          title: tracking_event.event.name.titleize,
          link: tracking_url(load_id: @shipment),
          description: "#{tracking_event.event.name.capitalize} in #{tracking_event.pretty_location} at #{ApplicationController.helpers.strip_tags(ApplicationController.helpers.pretty_date(
                                                                                                                                                     tracking_event.at, tracking_event.time_zone
                                                                                                                                                   ))}"
        }
      )
    end

    rss
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_load_id
    @load_id = params[:load_id]

    return if @load_id.blank?

    @load_id = @load_id.to_s.gsub(/[[:space:]]/, '').to_i
    @load_id = '' if @load_id.zero?
  end
end
