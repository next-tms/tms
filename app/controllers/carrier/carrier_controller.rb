class Carrier::CarrierController < ApplicationController
  before_action :restrict_to_carrier_users
  before_action :set_broker_carriers

  etag { [current_user&.companyable, account_customers, Setting.all] }

  private

  def account_customers = Customer.where(id: BrokerCustomer.where(id: @broker_carriers.select(:broker_customer_id)).select(:customer_id))

  def restrict_to_carrier_users
    return if current_user&.carrier?
    return unauthorized if current_user

    store_location_for(:user, request.fullpath) if request.get?
    redirect_to(root_path)
  end

  def set_broker_carriers = @broker_carriers = authorized_scope(BrokerCarrier.all).includes(broker_customer: :customer)
end
