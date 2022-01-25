# frozen_string_literal: true

class Broker::IntuitAccountController < Broker::BrokerController
  def show
    FetchQuickbooksCustomerIdsJob.perform_later(broker: current_user.broker)
  end
end
