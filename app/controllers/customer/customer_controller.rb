class Customer::CustomerController < ApplicationController
  before_action :restrict_to_customer_users

  private

  def restrict_to_customer_users
    return if current_user&.customer?
    return unauthorized if current_user

    store_location_for(:user, request.fullpath) if request.get?
    redirect_to(root_path)
  end
end
