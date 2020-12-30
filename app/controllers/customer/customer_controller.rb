# frozen_string_literal: true

class Customer::CustomerController < ApplicationController
  before_action :restrict_to_customer_users

  private

  def restrict_to_customer_users
    unless current_user&.customer?
      flash[:error] = 'Not authorized'
      redirect_to root_path and return
    end
  end
end
