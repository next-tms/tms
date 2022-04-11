# frozen_string_literal: true

class Broker::BrokerController < ApplicationController
  before_action :restrict_to_broker_users
  before_action :set_broker

  def settings; end

  def update
    if !@broker.update(broker_params)
      flash[:error] = "Unable to update #{@broker.name}: #{@broker.errors.full_messages.join(', ')}"
      redirect_back fallback_location: broker_settings_path
    else
      redirect_to broker_settings_path
    end
  end

  private

  def broker_params
    params.require(:broker).permit(
      :id,
      :automatically_authorize_receivables,
      :automatically_update_shipment_tracking_based_on_carrier_apis,
      broker_countries_attributes: %i[
        _destroy
        country_id
        id
      ]
    )
  end

  def restrict_to_broker_users
    unless current_user&.broker?
      flash[:error] = 'Not authorized'
      redirect_to root_path and return
    end
  end

  def set_broker
    @broker = current_user.broker
  end
end
