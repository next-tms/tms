# frozen_string_literal: true

class Broker::ContactsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_contact, only: %i[edit show update]

  def edit; end

  def index
    @q = @broker.contacts.includes(:contact).ransack(params[:q])
    @q.sorts = "#{"#{Contact.table_name}.first_name"} desc" if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def show; end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    render(:new) && return unless @contact.save

    redirect_to([:broker, @contact])
  end

  def update
    if !@contact.update(contact_params)
      flash[:error] = 'Unable to update contact'
      render(:edit)
    else
      redirect_to([:broker, @contact])
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params
    params.require(:contact).permit(
      :id,
      :companyable_sgid,
      :email,
      :first_name,
      :job_title,
      :last_name,
      :mobile_phone,
      :work_phone,
    )
  end
end
