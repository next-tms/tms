class Broker::Carriers::ContactsController < Broker::Carriers::BaseController
  def index
    @q = @carrier.contacts.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'first_name asc' if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end
end
