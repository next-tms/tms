class Broker::PickupsController < Broker::BrokerController
  before_action :authenticate_user!

  def create
    @pickup = Pickup.new(pickup_params)
    @pickup.dispatcher = current_user
    @pickup.updated_by = current_user

    unless @pickup.save
      flash[:error] = @pickup.errors.full_messages.to_sentence
      redirect_back_or_to([:quote, :broker, @pickup.shipment])
      return
    end

    DispatchShipmentPickupJob.perform_later(@pickup)
    flash[:success] = "Pickup request sent to #{@pickup.broker_carrier.carrier.name}"
    redirect_to([:broker, @pickup.shipment])
  end

  private

  def pickup_params = params.expect(pickup: [:rate_uid])
end
