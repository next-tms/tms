# frozen_string_literal: true

class Broker::PickupsController < Broker::BrokerController
  before_action :authenticate_user!

  def create
    @pickup = Pickup.new(pickup_params)
    @pickup.updated_by = current_user

    if @pickup.save
      DispatchShipmentPickupJob.perform_later(@pickup)
      flash[:success] = "Pickup request sent to #{@pickup.broker_carrier.carrier.name}"
      redirect_to broker_shipment_path(@pickup.shipment) and return
    else
      flash[:error] = @pickup.errors.full_messages.join('<br>').html_safe
      redirect_back(fallback_location: quote_broker_shipment_path(@pickup.shipment))
    end
  end

  private

  def pickup_params
    params.require(:pickup).permit(
      :rate_uid
    )
  end
end
