class AccountingConnectionsController < ApplicationController
  def callback
    %i[code state realmId].each do |key|
      raise ActionController::RoutingError, 'Missing required parameter(s)' if params[key].blank?
    end

    broker = Broker.find_by_uuid(params[:state])
    integration.service.connect!(code: params[:code], realm_id: params[:realmId], redirect_uri:)

    FetchBrokerCustomerAccountingCustomerIdsJob.perform_later(broker:)
    FetchBrokerCarrierAccountingVendorIdsJob.perform_later(broker:)

    flash[:success] = 'Accounting has been connected; data is being synced behind the scenes'

    redirect_to('http://localhost:3000/') and return if Rails.env.development?

    redirect_to(Setting.value!(:website_homepage), allow_other_host: true)
  end

  def connect
    redirect_to(integration.service.authorize_url(redirect_uri:, state: current_user.broker.uuid), allow_other_host: true)
  end

  def global_controller? = true

  private

  # @note QuickBooks is the only connectable accounting provider today; add a :kind param when Wave lands.
  def integration = @integration ||= Integration.quickbooks.first_or_initialize(name: 'default')

  def redirect_uri
    return oauth_callback_accounting_url if Rails.env.development?

    oauth_callback_accounting_url(host: 'tms.next-tms.com', protocol: 'https')
  end
end
