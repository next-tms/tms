# frozen_string_literal: true

class Broker::UsersController < Broker::BrokerController
  before_action :set_user, only: %i[destroy edit show update]
  before_action :authenticate_user!
  before_action :restrict_to_root

  def index
    @q = current_user.broker.users.includes(required_includes).ransack(params[:q])
    @q.sorts = 'contact.first_name desc' if @q.sorts.blank?

    @pagy, @users = pagy(@q.result)
  end

  def show; end

  def update
    @user.assign_attributes(user_params)

    if @user.save
      redirect_to broker_user_path(@user)
    else
      render :edit
    end
  end

  private

  def restrict_to_root
    require_role('root')
  end

  def set_user
    @user = current_user.broker.users.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(
      :broker_customer_id,
      :email,
      :first_name,
      :last_name,
      user_roles_attributes: %i[
        _destroy
        id
        role_id
      ]
    )
  end

  # Query helpers
  def required_includes
    %i[contact]
  end
end
