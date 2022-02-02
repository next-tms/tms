# frozen_string_literal: true

class Broker::RatesController < Broker::BrokerController
  before_action :set_rate

  def breakdown_modal
    render layout: 'modal'
  end

  private

  def set_rate
    @rate = current_user.broker.rates.find_by_uid(params[:uid])
  end
end
