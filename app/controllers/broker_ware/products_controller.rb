class BrokerWare::ProductsController < BrokerWare::ApplicationController
  def index
    authorize!(broker_customer, to: :view?)

    @products = []
  end
end
