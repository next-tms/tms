class Broker::AccountingController < Broker::BrokerController
  def show = authorize!(current_user, to: :show?, with: AccountingPolicy)
end
