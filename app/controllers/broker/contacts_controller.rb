# frozen_string_literal: true

class Broker::ContactsController < Broker::BrokerController
  before_action :set_contact, only: %i[show edit update destroy]
  before_action :authenticate_user!

  def index; end

  def new
    @customer_contact = CustomerContact.new
    @customer_contact.broker = @broker_customer.broker
    @customer_contact.customer = @broker_customer.customer
    @customer_contact.contact = Contact.new
  end

  def create
    @customer_contact = CustomerContact.new(customer_contact_params)
    @customer_contact.broker = @broker_customer.broker
    @customer_contact.customer = @broker_customer.customer
    if @customer_contact.save
      redirect_to [:broker, @broker_customer, @customer_contact]
    else
      render :new
    end
  end

  def edit; end

  def update
    if !@contact.update(contact_params)
      flash[:danger] = 'Unable to update contact'
      render :edit
    else
      redirect_to broker_contacts_path
    end
  end

  def show
    unless @customer_contact.broker == current_user.broker
      render file: 'public/401', layout: false, status: :unauthorized
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params; end
end
