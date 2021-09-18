# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :add_floc_opt_out_header
  before_action :check_website, :check_if_website_belongs_to_broker
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

  private

  def add_floc_opt_out_header
    response.set_header('Permissions-Policy', 'interest-cohort=()')
  end

  def check_website_belongs_to_broker
    if current_user
      if @website
        raise ApplicationController::NotAuthorized unless current_user.broker == @website.broker
      else
        # User logged into Liftoff directly
        raise ApplicationController::NotAuthorized
      end
    end
  end

  def check_website
    @website ||= Website.find_by_domain(request.host) || nil
    redirect_to 'https://next-tms.com/' and return if @website.blank?
  end

  def user_sign_in_path
    return @user_sign_in_path = root_path unless current_user

    @user_sign_in_path = if current_user.customer?
                           customer_shipments_path
                         else
                           broker_shipments_path
                         end
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || user_sign_in_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    @website.manifest.dig('landings', 'sign-out', 'url') || root_path
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
