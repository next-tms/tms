class AccountingConnectionsController < ApplicationController
  PROVIDERS = { 'quickbooks' => 'intuit', 'wave' => 'wave' }.freeze

  def callback
    unless valid_nonce? && required_params.all? { |key| params[key].present? }
      redirect_to(%i[broker settings company accounting], flash: { error: t('.failure') })
      return
    end

    integration.service.connect!(code: params[:code], realm_id: params[:realmId], redirect_uri:)

    FetchBrokerCustomerAccountingCustomerIdsJob.perform_later
    FetchBrokerCarrierAccountingVendorIdsJob.perform_later

    redirect_to(%i[broker settings company accounting], flash: { success: t('.success') })
  end

  def connect
    session[:accounting_oauth_nonce] = SecureRandom.hex(16)

    url = integration.service.authorize_url(redirect_uri:, state:)

    response.set_header('Referrer-Policy', 'no-referrer')
    redirect_to(url, allow_other_host: true)
  end

  def global_controller? = true

  private

  def callback_url_helper = :"oauth_callback_#{kind}_accounting_url"
  def flight_url = ENV.fetch('FLIGHT_URL', nil)
  def integration = @integration ||= Integration.where(kind:).first_or_initialize(name: 'default')
  def kind = params[:kind].presence || 'quickbooks'
  def provider = PROVIDERS.fetch(kind)
  def redirect_uri = flight_url.present? ? "#{flight_url}/oauth/callback/#{provider}" : public_send(callback_url_helper)
  def required_params = kind == 'quickbooks' ? %i[code realmId] : %i[code]
  def state = flight_url.present? ? "#{ENV.fetch('FLIGHT_APP_ID')}.#{session[:accounting_oauth_nonce]}" : session[:accounting_oauth_nonce]

  def valid_nonce?
    (nonce = session.delete(:accounting_oauth_nonce)).present? && ActiveSupport::SecurityUtils.secure_compare(
      params[:state].to_s.split('.', 2).last.to_s, nonce
    )
  end
end
