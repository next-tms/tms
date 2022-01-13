# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :add_floc_opt_out_header
  before_action :check_website, :check_if_website_belongs_to_broker
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :sign_out_deactivated_user

  protect_from_forgery with: :exception

  # Rescue from invalid authenticity token
  rescue_from ActionController::InvalidAuthenticityToken, with: :bad_token
  def bad_token
    redirect_to '/' and return
  end

  def require_role(role_name)
    unauthorized unless current_user&.has_role?(role_name)
  end

  def not_require_role(role_name)
    unauthorized if current_user&.has_role?(role_name)
  end

  def unauthorized
    render layout: false, file: 'public/401.html', status: :unauthorized
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

  def check_website
    @website ||= Website.find_by_domain(request.host) || nil
    redirect_to('https://next-tms.com/', allow_other_host: true) if @website.blank?
  end

  def sign_out_deactivated_user
    sign_out_and_redirect(current_user) and return if signed_in? && current_user.deactivated?
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
    set_flash_message! :alert, :warn_pwned if resource.respond_to?(:pwned?) && resource.pwned?

    stored_location_for(resource_or_scope) || user_sign_in_path
  end

  # def after_sign_out_path_for(_resource_or_scope)
  #   check_website
  #   @website.manifest.dig('landings', 'sign-out', 'url') || root_path
  # end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[email first_name last_name password password_confirmation]
    )

    devise_parameter_sanitizer.permit(
      :accept_invitation,
      keys: %i[email broker_customer_id first_name last_name]
    )

    devise_parameter_sanitizer.permit(
      :invite,
      keys: [
        :email,
        :broker_customer_id,
        :contact_id,
        :first_name,
        :last_name,
        { user_roles_attributes: %i[_destroy role_id] }
      ]
    )
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
