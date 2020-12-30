# frozen_string_literal: true

class Broker::BrokerController < ApplicationController
  before_action :restrict_to_broker_users

  private

  def restrict_to_broker_users
    unless current_user&.broker?
      flash[:error] = 'Not authorized'
      redirect_to root_path and return
    end
  end
end
