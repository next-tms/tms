# frozen_string_literal: true

class Broker::ContactsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_contact, only: %i[edit show update]
  before_action :set_broker_carrier, only: %i[edit show update]
  before_action :set_broker_customer, only: %i[edit show update]

  def edit; end

  def index
    @q = @broker.contacts.includes(:contact).ransack(params[:q])
    @q.sorts = "#{Contact.table_name + '.first_name'} desc" if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def show
    unauthorized unless @contact.broker == current_user.broker
  end

  def new
    @contact = Contact.new
    @contact.broker_carrier = params[:broker_carrier_id].blank? ? nil : BrokerCarrier.find(params[:broker_carrier_id])
    @contact.broker_customer = params[:broker_customer_id].blank? ? nil : BrokerCustomer.find(params[:broker_customer_id])

    @broker_carrier = @contact.broker_carrier
    @broker_customer = @contact.broker_customer
  end

  def create
    @contact = Contact.new(contact_params)
    @contact.broker = current_user.broker

    if @contact.save
      redirect_to [:broker, @contact]
    else
      render :new
    end
  end

  def update
    if !@contact.update(contact_params)
      flash[:error] = 'Unable to update contact'
      render :edit
    else
      redirect_to [:broker, @contact]
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_carrier
    @broker_carrier = @contact.broker_carrier
  end

  def set_broker_customer
    @broker_customer = @contact.broker_customer
  end

  def set_contact
    @contact = Contact.find params[:id]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params
    params.require(:contact).permit(
      :id,
      :broker_carrier_id,
      :broker_customer_id,
      :email,
      :first_name,
      :job_title,
      :last_name,
      :mobile_phone,
      :work_phone
   )
  end
end
