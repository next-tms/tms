# frozen_string_literal: true

class Broker::BrokerCarrierContactsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_broker_carrier
  before_action :set_broker_carrier_contact, only: %i[edit show update]

  def edit; end

  def index
    @q = @broker_carrier.broker_carrier_contacts.includes(:contact).ransack(params[:q])
    @q.sorts = "#{Contact.table_name + '.first_name'} desc" if @q.sorts.blank?
    @pagy, @broker_carrier_contacts = pagy(@q.result)
  end

  def show
    unauthorized unless @broker_carrier_contact.broker_carrier.broker == current_user.broker
  end

  def new
    @broker_carrier_contact = BrokerCarrierContact.new
    @broker_carrier_contact.contact = Contact.new
  end

  def create
    @broker_carrier_contact = BrokerCarrierContact.new(broker_carrier_contact_params)
    @broker_carrier_contact.broker_carrier = @broker_carrier

    if @broker_carrier_contact.save
      redirect_to [:broker, @broker_carrier, @broker_carrier_contact]
    else
      render :new
    end
  end

  def update
    if !@broker_carrier_contact.update(broker_carrier_contact_params)
      flash[:error] = 'Unable to update contact'
      render :edit
    else
      redirect_to [:broker, @broker_carrier, @broker_carrier_contact]
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_carrier
    @broker_carrier = BrokerCarrier.find params[:broker_carrier_id]
  end

  def set_broker_carrier_contact
    @broker_carrier_contact = BrokerCarrierContact.find params[:id]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def broker_carrier_contact_params
    params.require(:broker_carrier_contact).permit(
      :id,
      :broker_carrier_id,
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
