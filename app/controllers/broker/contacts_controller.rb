class Broker::ContactsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_contact, only: %i[edit show update]

  def edit; end

  def show; end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    unless @contact.save
      render(:new)
      return
    end

    redirect_to([:broker, @contact])
  end

  def update
    unless @contact.update(contact_params)
      flash[:error] = t('.failure')
      render(:edit)
      return
    end

    redirect_to([:broker, @contact])
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params
    params.expect(contact: %i[id companyable_sgid email first_name job_title last_name mobile_phone work_phone])
  end
end
