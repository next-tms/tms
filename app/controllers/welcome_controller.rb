class WelcomeController < ApplicationController
  def index
    return redirect_to(stored_location_for(:user) || after_sign_in_path) if user_signed_in?

    redirect_to(new_user_session_path)
  end

  def after_sign_in_path
    return carrier_root_path if current_user.carrier?
    return customer_shipments_path if current_user.customer?

    yours_broker_problems_path if current_user.broker?
  end
end
