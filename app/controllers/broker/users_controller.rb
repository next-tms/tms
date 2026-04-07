class Broker::UsersController < Broker::BrokerController
  before_action :authenticate_user!
  before_action -> { require_role('root') }, except: %i[impersonate stop_impersonating]

  before_action :set_user, only: %i[edit impersonate show update]

  def edit; end

  def impersonate
    impersonate_user(@user)
    redirect_to(root_path, status: :see_other)
  end

  def index
    @q = User.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'first_name asc' if @q.sorts.blank?

    @pagy, @users = pagy(@q.result)
  end

  def show; end

  def stop_impersonating
    stop_impersonating_user
    redirect_to(root_path, status: :see_other)
  end

  def update
    @user.assign_attributes(user_params)

    # Manually map new roles and roles that are marked for deletion because
    # the Contact#accept_nested_attributes is not triggered on #update since we are
    # not updating or tou the @user.contact record
    new_roles = @user.contact.contact_roles.select(&:new_record?)
    new_roles.map(&:save!) if new_roles

    removeable_roles = @user.contact.contact_roles.select(&:_destroy)
    removeable_roles.map(&:destroy!) if removeable_roles.present?

    if @user.save
      flash[:success] = 'Successfully Updated User'
      redirect_to(broker_user_path(@user))
    else
      render(:edit)
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :companyable_sgid,
      :deactivated,
      :email,
      :first_name,
      :last_name,
      :phone,
      contact_attributes: [
                            :id,
                            contact_roles_attributes: %i[_destroy id role]
                          ],
    )
  end

  # Query helpers
  def required_includes
    %i[companyable]
  end
end
