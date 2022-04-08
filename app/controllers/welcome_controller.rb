# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to customer_shipments_path and return if current_user.customer?
      redirect_to unresolved_broker_problems_path and return if current_user.broker?
    elsif @website
      redirect_to new_user_session_path and return
    end
  end
end
