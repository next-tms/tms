class Broker::BrokerController < ApplicationController
  COMPANY_SETTING_KEYS = %w[mailing_address customer_service_email phone].freeze

  before_action :restrict_to_broker_users

  def settings
    @broker_countries = BrokerCountry.eager_load(:country).order('countries.name')
    @settings = Setting.where(key: COMPANY_SETTING_KEYS).index_by(&:key)
  end

  private

  def restrict_to_broker_users
    user = true_user || current_user
    return if user&.broker?
    return unauthorized if user

    store_location_for(:user, request.fullpath) if request.get?
    redirect_to(root_path)
  end
end
