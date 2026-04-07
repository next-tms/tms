# frozen_string_literal: true

class TrackingController < ApplicationController
  before_action :set_load_id

  def show
    @shipment = if @load_id.present?
                  Shipment.active.find_by(load_id: @load_id) ||
                    Shipment.active.find_by(pro: @load_id) ||
                    Shipment.active.find_by(bol: @load_id)
                end

    @shipment.update_tracking_events if @shipment.present?

    respond_to do |format|
      format.html
      format.rss do
        render(:no_content) and return if @shipment.blank?

        render(plain: rss, content_type: 'application/rss+xml')
      end
    end
  end

  private

  def rss
    desc = [ "Tracking events for Load #{@shipment.load_id} (#{@website.broker.name})" ]
    desc << "\n\nNotes:\n#{@shipment.public_notes}" if @shipment.public_notes.present?

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
        },
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
