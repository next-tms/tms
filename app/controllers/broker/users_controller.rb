# frozen_string_literal: true

class Broker::UsersController < Broker::BrokerController
  before_action :set_user, only: %i[destroy edit impersonate show update]
  before_action :authenticate_user!
  before_action :restrict_to_root, except: %i[impersonate stop_impersonating]

  def index
    @q = User.includes(required_includes).ransack(params[:q])
    @q.sorts = 'first_name asc' if @q.sorts.blank?

    @pagy, @users = pagy(@q.result)
  end

  def show; end

  def update
    @user.assign_attributes(user_params)

    if @user.save
      redirect_to(broker_user_path(@user))
    else
      render(:edit)
    end
  end

  def impersonate
    impersonate_user(@user)
    redirect_to(root_path, status: :see_other)
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to(root_path, status: :see_other)
  end

  private

  def restrict_to_root
    require_role('root')
  end

  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(
      :company_sgid,
      :deactivated,
      :email,
      :first_name,
      :last_name,
      :phone,
      user_roles_attributes: %i[
                               _destroy
                               id
                               role_id
                             ],
    )
  end

  # Query helpers
  def required_includes
    %i[user_roles roles companyable]
  end
end
