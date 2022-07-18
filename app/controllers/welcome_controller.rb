# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    redirect_to after_sign_in_path and return if user_signed_in?

    redirect_to new_user_session_path and return if @website
  end

  def after_sign_in_path
    return customer_shipments_path if current_user.customer?

    unresolved_broker_problems_path if current_user.broker
  end
end
