# frozen_string_literal: true

class IntuitAccountsController < ApplicationController
  def authenticate
    redirect_uri = oauth_callback_intuit_account_url_with_host

    grant_url = intuit_oauth2_client.auth_code.authorize_url(
      redirect_uri:,
      response_type: 'code',
      state: current_user.broker.uuid,
      scope: 'com.intuit.quickbooks.accounting',
    )

    redirect_to(grant_url, allow_other_host: true)
  end

  def oauth_callback
    %i[code state realmId].each do |key|
      raise ActionController::RoutingError, 'Missing required parameter(s)' unless params[key].present?
    end

    broker = Broker.find_by_uuid(params[:state])
    redirect_uri = oauth_callback_intuit_account_url_with_host
    response = intuit_oauth2_client.auth_code.get_token(params[:code], redirect_uri:)

    raise ActionController::RoutingError, 'Invalid response' unless response

    intuit_account = broker.intuit_account || broker.build_intuit_account

    intuit_account.assign_attributes(
      encrypted_oauth2_access_token: response.token,
      encrypted_oauth2_refresh_token: response.refresh_token,
      realm_id: params[:realmId],
    )
    intuit_account.save!

    FetchBrokerCustomerQuickbooksCustomerIdsJob.perform_later(broker:)
    FetchBrokerCarrierQuickbooksVendorIdsJob.perform_later(broker:)

    flash[:success] = 'QuickBooks has been connected; data is being synced behind the scenes'

    redirect_to('http://localhost:3000/') and return if Rails.env.development?

    redirect_to(Setting.value!(:website_homepage), allow_other_host: true)
  end

  def global_controller?
    true
  end

  private

  def intuit_oauth2_client
    args = [
             ENV.fetch('INTUIT_CLIENT_ID'),
             ENV.fetch('INTUIT_CLIENT_SECRET'),
             {
               authorize_url: 'https://appcenter.intuit.com/connect/oauth2',
               site: 'https://appcenter.intuit.com/connect/oauth2',
               token_url: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer'
             }
           ]

    OAuth2::Client.new(*args)
  end

  def oauth_callback_intuit_account_url_with_host
    return oauth_callback_intuit_account_url if Rails.env.development?

    oauth_callback_intuit_account_url(host: 'tms.next-tms.com', protocol: 'https')
  end
end
