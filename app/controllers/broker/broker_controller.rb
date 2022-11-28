# frozen_string_literal: true

class Broker::BrokerController < ApplicationController
  before_action :restrict_to_broker_users
  before_action :set_broker

  def settings
    @notification_types = Notification.notification_types
    @splitted_notification_types = @notification_types.each_slice(@notification_types.size / 2).to_a
    @blacklist = current_user.email_notifications_blacklist || []
  end

  def update
    blacklist = Notification.notification_types - (params[:email_notifications_blacklist] || [])
    current_user.update(email_notifications_blacklist: blacklist.join(','))

    redirect_to broker_settings_path and return if @broker.update(broker_params)

    flash[:error] = "Unable to update #{@broker.name}: #{@broker.errors.full_messages.join(', ')}"
    redirect_back fallback_location: broker_settings_path
  end

  private

  def broker_params
    params.require(:broker).permit(
      :id,
      :automatically_authorize_receivables,
      :automatically_update_shipment_tracking_based_on_carrier_apis,
      :customer_service_email,
      :ignore_broker_carrier_bol_requires_tracking_number,
      :phone,
      :requires_charges_confirmed_on_receivables,
      address_attributes: %i[
        id
        street
        street2
        city
        region_id
        zip_code
        country_id
      ],
      broker_countries_attributes: %i[
        _destroy
        country_id
        id
      ]
    )
  end

  def restrict_to_broker_users
    user = true_user || current_user
    return if user&.broker?

    store_location_for(:user, request.fullpath) if request.get?

    flash[:error] = 'Not authorized'
    redirect_to root_path and return
  end

  def set_broker
    @broker = current_user.broker
  end
end
