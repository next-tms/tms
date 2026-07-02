class Broker::BrokerController < ApplicationController
  before_action :restrict_to_broker_users
  before_action :set_broker

  def settings; end

  def update
    return redirect_to(broker_settings_company_path) if @broker.update(broker_params)

    render('edit')
  end

  private

  def broker_params
    params.require(:broker).permit(
      :id,
      :automatically_authorize_receivables,
      :customer_service_email,
      :ignore_broker_carrier_bol_requires_tracking_number,
      :phone,
      :requires_charges_confirmed_on_receivables,
      :theme_primary_color,
      :theme_sidebar_background_color,
      :theme_sidebar_text_color,
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
                                   ],
    )
  end

  def restrict_to_broker_users
    user = true_user || current_user
    return if user&.broker?
    return unauthorized if user

    store_location_for(:user, request.fullpath) if request.get?
    redirect_to(root_path)
  end

  def set_broker
    @broker = current_user.broker
  end
end
