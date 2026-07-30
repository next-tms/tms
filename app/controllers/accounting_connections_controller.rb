class AccountingConnectionsController < ApplicationController
  PROVIDERS = { 'quickbooks' => 'intuit', 'wave' => 'wave' }.freeze

  def callback
    raise ActionController::RoutingError, 'Invalid state' unless valid_nonce?

    required_params.each { |key| raise ActionController::RoutingError, 'Missing required parameter(s)' if params[key].blank? }

    integration.service.connect!(code: params[:code], realm_id: params[:realmId], redirect_uri:)

    FetchBrokerCustomerAccountingCustomerIdsJob.perform_later(broker:)
    FetchBrokerCarrierAccountingVendorIdsJob.perform_later(broker:)

    flash[:success] = 'Connected'

    if Rails.env.development?
      redirect_to(root_path)
      return
    end

    redirect_to(Setting.value!(:website_homepage), allow_other_host: true)
  end

  def connect
    session[:accounting_oauth_nonce] = SecureRandom.hex(16)

    url = integration.service.authorize_url(redirect_uri:, state:)

    redirect_to(url, allow_other_host: true)
  end

  def global_controller? = true

  private

  def broker = current_user.broker
  def callback_url_helper = :"oauth_callback_#{kind}_accounting_url"
  def integration = @integration ||= Integration.where(kind:).first_or_initialize(name: 'default')
  def kind = params[:kind].presence || 'quickbooks'
  def provider = PROVIDERS.fetch(kind)
  def required_params = kind == 'quickbooks' ? %i[code realmId] : %i[code]

  def redirect_uri
    return public_send(callback_url_helper) if Rails.env.development?

    "#{ENV.fetch('INTEGRATIONS_RELAY_URL', 'https://flight.next-tms.com/oauth/callback')}/#{provider}"
  end

  def state = "#{ENV.fetch('FLIGHT_APP_ID')}.#{session[:accounting_oauth_nonce]}"

  def valid_nonce?
    (nonce = session.delete(:accounting_oauth_nonce)).present? && ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s.split('.', 2).last.to_s, nonce)
  end
end
