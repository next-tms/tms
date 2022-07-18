# frozen_string_literal: true

module QuickbooksOauth
  extend ActiveSupport::Concern

  def perform_authenticated_request
    attempts = 0
    begin
      yield oauth_access_token
    rescue OAuth2::Error, Quickbooks::AuthorizationFailure => e
      Rails.logger.info("QuickbooksOauth.perform: #{e.message}")

      # to prevent an infinite loop here keep a counter and bail out after N times...
      attempts += 1

      raise 'QuickbooksOauth:ExceededAuthAttempts' if attempts >= 3

      # check if its an invalid_grant first, but assume it is for now
      refresh_token!

      retry
    end
  end

  def refresh_token!
    t = oauth_access_token
    refreshed = t.refresh!

    oauth2_refresh_token_expires_at = if refreshed.params['x_refresh_token_expires_in'].to_i.positive?
                                        Time.now + refreshed.params['x_refresh_token_expires_in'].to_i.seconds
                                      else
                                        100.days.from_now
                                      end

    update(
      encrypted_oauth2_access_token: refreshed.token,
      encrypted_oauth2_refresh_token: refreshed.refresh_token,
      oauth2_access_token_expires_at: Time.at(refreshed.expires_at),
      oauth2_refresh_token_expires_at:
    )
  end

  def oauth_client
    self.class.construct_oauth2_client
  end

  def oauth_access_token
    OAuth2::AccessToken.new(oauth_client, encrypted_oauth2_access_token, refresh_token: encrypted_oauth2_refresh_token)
  end

  def consumer
    oauth_access_token
  end

  module ClassMethods
    def construct_oauth2_client
      options = {
        site: 'https://appcenter.intuit.com/connect/oauth2',
        authorize_url: 'https://appcenter.intuit.com/connect/oauth2',
        token_url: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer'
      }

      OAuth2::Client.new(
        Rails.application.credentials.intuit.client_id,
        Rails.application.credentials.intuit.client_secret,
        options
      )
    end
  end
end
