class StripeAccountsController < ApplicationController
  before_action :set_broker

  def authenticate
    Stripe.api_key = ENV.fetch('STRIPE_API_KEY')

    account = Stripe::Account.create(type: 'standard').id

    url = Stripe::AccountLink.create(
      account:,
      refresh_url: oauth_callback_refresh_stripe_account_url_with_host(state: @broker.uuid),
      return_url: oauth_callback_stripe_account_url_with_host(account:, state: @broker.uuid),
      type: 'account_onboarding'
    ).url

    redirect_to url, allow_other_host: true
  end

  def oauth_callback
    if params[:account].blank?
      flash[:error] = 'Unknown error'
      redirect_to broker_settings_stripe_url(host: ENV.fetch('DOMAIN')), allow_other_host: true and return
    end

    Stripe.api_key = ENV.fetch('STRIPE_API_KEY')
    account = Stripe::Account.retrieve(params[:account])

    if account.charges_enabled?
      StripeAccount.create(
        broker:,
        encrypted_account_id: account.id
      )

      flash[:success] = 'Stripe connected successfully'
    else
      flash[:error] = 'Your account does not accept payments'
    end

    redirect_to broker_settings_stripe_url(host: ENV.fetch('DOMAIN')), allow_other_host: true
  end

  def oauth_callback_refresh
    redirect_to authenticate_stripe_account_url(host: ENV.fetch('DOMAIN'))
  end

  def global_controller?
    true
  end

  private

  def oauth_callback_stripe_account_url_with_host(options)
    options = options.merge(host: 'tms.next-tms.com', protocol: 'https') unless Rails.env.development?

    oauth_callback_stripe_account_url(options)
  end

  def oauth_callback_refresh_stripe_account_url_with_host(options)
    options = options.merge(host: 'tms.next-tms.com', protocol: 'https') unless Rails.env.development?

    oauth_callback_refresh_stripe_account_url(options)
  end

  def set_broker
    @broker = Broker.find_by_uuid(params[:state])
  end
end
