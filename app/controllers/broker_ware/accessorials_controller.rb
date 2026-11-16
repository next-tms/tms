class BrokerWare::AccessorialsController < BrokerWare::ApplicationController
  def index
    authorize!(broker_customer, to: :view?)

    @broker_accessorials = broker_customer.eligible_broker_accessorials.where.not(accessorial: nil).includes(:accessorial)

    stale?(@broker_accessorials, Accessorial.where(id: @broker_accessorials.select(:accessorial_id)))
  end
end
