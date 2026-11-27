class BrokerWare::AccessorialsController < BrokerWare::ApplicationController
  before_action :set_accessorials

  def index
    authorize!(broker_customer, to: :view?)

    stale?(*@accessorials)
  end

  private

  def set_accessorials = @accessorials = authorized_scope(Accessorial.all).catalog
end
