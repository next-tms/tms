class Broker::Carriers::BaseController < Broker::BrokerController
  before_action :authenticate_user!
  before_action -> { authorize!(current_user, to: :show?, with: BrokerPolicy) }
  before_action :set_carrier

  private

  def authorize_accounts_payable = authorize!(current_user, to: :accounts_payable_show?, with: AccountingPolicy)
  def set_carrier = @carrier = Carrier.where(id: BrokerCarrier.select(:carrier_id)).find(params.expect(:carrier_id))
end
