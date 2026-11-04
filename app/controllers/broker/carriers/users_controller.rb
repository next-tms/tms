class Broker::Carriers::UsersController < Broker::Carriers::BaseController
  def index
    @q = @carrier.users.includes(:contact).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'first_name asc' if @q.sorts.blank?
    @pagy, @users = pagy(@q.result)
    @uninvited_contacts = @carrier.contacts.where.missing(:user).where.not(email: [nil, '']).order(:first_name)
  end
end
