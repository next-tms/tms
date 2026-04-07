class ApplicationController < ActionController::Base
  include Pagy::Backend
  impersonates :user

  before_action :add_floc_opt_out_header
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :sign_out_deactivated_user

  protect_from_forgery with: :exception

  rescue_from ActionPolicy::Unauthorized, with: :unauthorized

  # Rescue from invalid authenticity token
  rescue_from ActionController::InvalidAuthenticityToken, with: :bad_token
  def bad_token
    redirect_to('/') && return
  end

  def require_role(role)
    unauthorized unless current_user&.role?(role)
  end

  def not_require_role(role)
    unauthorized if current_user&.role?(role)
  end

  def unauthorized
    render(layout: false, file: 'public/401.html', status: :unauthorized)
  end

  protected

  def add_floc_opt_out_header
    response.set_header('Permissions-Policy', 'interest-cohort=()')
  end

  def check_if_website_belongs_to_broker
    if current_user
      raise ApplicationController::NotAuthorized if !@website || current_user.broker_id != @website.broker_id

      # User logged into Liftoff directly
      raise ApplicationController::NotAuthorized unless @website
    end
  end

  def global_controller?
    false
  end

  def sign_out_deactivated_user
    sign_out_and_redirect(current_user) && return if signed_in? && current_user.deactivated?
  end

  def user_sign_in_path
    return @user_sign_in_path = root_path unless current_user

    @user_sign_in_path = if current_user.customer?
                           customer_shipments_path
                         else
                           broker_shipments_path
                         end
  end

  # Devise

  def after_sign_in_path_for(resource_or_scope)
    set_flash_message!(:alert, :warn_pwned) if resource.respond_to?(:pwned?) && resource.pwned?

    stored_location_for(resource_or_scope) || user_sign_in_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[
              email
              email_notifications_blacklist
              first_name
              last_name
              password
              password_confirmation
              phone
              receive_email_notifications
              receive_notifications_from_self
              receive_read_notifications_by_email
              receive_sms_notifications
            ],
    )

    devise_parameter_sanitizer.permit(
      :accept_invitation,
      keys: %i[email broker_customer_id first_name last_name phone],
    )

    devise_parameter_sanitizer.permit(
      :invite,
      keys: [
              :broker_customer_id,
              :companyable_id,
              :companyable_type,
              :contact_id,
              :contact_id,
              :email,
              :email,
              :first_name,
              :last_name,
              :phone,
              { user_roles_attributes: %i[_destroy role_id] },
              { contact_attributes: { contact_roles_attributes: %i[_destroy role] } }
            ],
    )
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
