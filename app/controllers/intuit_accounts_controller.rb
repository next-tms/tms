# frozen_string_literal: true

class IntuitAccountsController < ApplicationController
  def authenticate
    redirect_uri = oauth_callback_intuit_account_url_with_host

    grant_url = intuit_oauth2_client.auth_code.authorize_url(
      redirect_uri:,
      response_type: 'code',
      state: current_user.broker.uuid,
      scope: 'com.intuit.quickbooks.accounting'
    )

    redirect_to grant_url, allow_other_host: true
  end

  def oauth_callback
    if params[:state].present?
      broker = Broker.find_by_uuid(params[:state])
      redirect_uri = oauth_callback_intuit_account_url_with_host

      if response = intuit_oauth2_client.auth_code.get_token(params[:code], redirect_uri:)
        intuit_account = broker.intuit_account || broker.build_intuit_account

        intuit_account.assign_attributes(
          encrypted_oauth2_access_token: response.token,
          encrypted_oauth2_refresh_token: response.refresh_token,
          realm_id: params[:realmId]
        )

        intuit_account.save
        FetchQuickbooksCustomerIdsJob.perform_later(broker:)
      end
    end

    redirect_to 'http://localhost:3000/' and return if Rails.env.development?

    redirect_to "https://#{broker.websites.first.domain}/", allow_other_host: true
  end

  def global_controller?
    true
  end

  private

  def intuit_oauth2_client
    intuit_oauth_params = {
      site: 'https://appcenter.intuit.com/connect/oauth2',
      authorize_url: 'https://appcenter.intuit.com/connect/oauth2',
      token_url: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer'
    }

    intuit_oauth2_client = OAuth2::Client.new(
      Rails.application.credentials.intuit.client_id,
      Rails.application.credentials.intuit.client_secret,
      intuit_oauth_params
    )
  end

  def oauth_callback_intuit_account_url_with_host
    return oauth_callback_intuit_account_url if Rails.env.development?

    oauth_callback_intuit_account_url(host: 'tms.next-tms.com', protocol: 'https')
  end
end
