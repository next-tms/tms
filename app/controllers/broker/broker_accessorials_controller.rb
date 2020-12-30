# frozen_string_literal: true

class Broker::BrokerAccessorialsController < Broker::BrokerController
  before_action :set_broker_accessorial, only: %i[show edit update]
  before_action :authenticate_user!

  def index
    @broker_accessorials = current_user.broker.broker_accessorials.order(:name)
  end

  #  def new
  #    @broker_accessorial = BrokerCustomer.new
  #    @broker_accessorial.broker = current_user.broker
  #    @broker_accessorial.customer = Customer.new
  #  end
  #
  #  def create
  #    @broker_accessorial = BrokerCustomer.new(broker_accessorial_params)
  #    @broker_accessorial.broker = current_user.broker
  #    if @broker_accessorial.save
  #      redirect_to [:broker, @broker_accessorial]
  #    else
  #      render :new
  #    end
  #  end
  #
  #  def edit
  #  end
  #
  #  def update
  #    if not @broker_accessorial.update(broker_accessorial_params)
  #      flash[:danger] = 'Unable to update customer'
  #      render :edit
  #    else
  #      redirect_to [:broker, @broker_accessorial, @customer_contact]
  #    end
  #  end
  #
  #  def show
  #    if @broker_accessorial.broker == current_user.broker
  #      @broker_carriers = BrokerCarrier.where broker: @broker_accessorial.broker, customer: @broker_accessorial.customer
  #      @shipments = Shipment.where(customer: @broker_accessorial.customer).order(created_at: :desc).limit(5)
  #      @customer_contacts = @broker_accessorial.customer.customer_contacts
  #    else
  #      render file: 'public/401', layout: false, status: :unauthorized
  #    end
  #  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_accessorial
    @broker_accessorial = BrokerCustomer.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def broker_accessorial_params
    params.require(:broker_accessorial).permit(:id)
  end
end
