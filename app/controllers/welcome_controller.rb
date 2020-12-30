# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to customer_shipments_path and return if current_user.customer?
      redirect_to broker_shipments_path and return if current_user.broker?
    else
      redirect_to new_user_session_path and return if @website
    end
  end
end
