class Broker::Shipments::TrackingEventsController < Broker::Shipments::BaseController
  def edit = authorize!(@shipment, to: :view?)
  def show = authorize!(@shipment, to: :view?)

  def update
    authorize!(@shipment, to: :manage?)

    @shipment.assign_attributes(tracking_events_attributes: tracking_events_params)
    @shipment.updated_by = current_user

    unless @shipment.save
      render(:edit, status: :unprocessable_content)
      return
    end

    redirect_to([:broker, @shipment, :tracking_events])
  end

  private

  def tracking_events_params
    params.expect(
      tracking_events: [[
        :_destroy,
        :at,
        :city,
        :country_alpha2,
        :event_id,
        :id,
        :public,
        :region_iso31662,
        { address_attributes: %i[city id region_iso31662 street street2 zip_code] }
      ]]
    )
  end
end
