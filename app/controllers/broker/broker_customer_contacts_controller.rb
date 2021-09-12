# frozen_string_literal: true

class Broker::BrokerCustomerContactsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_broker_customer
  before_action :set_broker_customer_contact, only: %i[edit show update]

  def edit; end

  def index
    @q = @broker_customer.broker_customer_contacts.includes(:contact).ransack(params[:q])
    @q.sorts = "#{Contact.table_name + '.first_name'} desc" if @q.sorts.blank?
    @pagy, @broker_customer_contacts = pagy(@q.result)
  end

  def show
    unauthorized unless @broker_customer_contact.broker_customer.broker == current_user.broker
  end

  def new
    @broker_customer_contact = BrokerCustomerContact.new
    @broker_customer_contact.contact = Contact.new
  end

  def create
    @broker_customer_contact = BrokerCustomerContact.new(broker_customer_contact_params)
    @broker_customer_contact.broker_customer = @broker_customer

    if @broker_customer_contact.save
      redirect_to [:broker, @broker_customer, @broker_customer_contact]
    else
      render :new
    end
  end

  def update
    if !@broker_customer_contact.update(broker_customer_contact_params)
      flash[:error] = 'Unable to update contact'
      render :edit
    else
      redirect_to [:broker, @broker_customer, @broker_customer_contact]
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_customer
    @broker_customer = BrokerCustomer.find params[:broker_customer_id]
  end

  def set_broker_customer_contact
    @broker_customer_contact = BrokerCustomerContact.find params[:id]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def broker_customer_contact_params
    params.require(:broker_customer_contact).permit(
      :id,
      :broker_customer_id,
      :contact_id,
      contact_attributes: [
        :id,
        :email,
        :first_name,
        :job_title,
        :last_name,
        :mobile_phone,
        :work_phone
      ]
    )
  end
end
