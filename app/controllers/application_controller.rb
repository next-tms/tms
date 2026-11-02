class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :add_floc_opt_out_header
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :sign_out_deactivated_user

  delegate :homepage, private: true, to: :helpers

  etag { [current_user, Setting.all] }

  impersonates :user

  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken, with: :bad_token
  rescue_from ActionPolicy::Unauthorized, with: :unauthorized

  def bad_token = redirect_to('/')
  def not_require_role(role) = (unauthorized if current_user&.role?(role))
  def require_role(role) = (unauthorized unless current_user&.role?(role))
  def unauthorized = render(layout: false, file: 'public/404.html', status: :not_found)

  protected

  def add_floc_opt_out_header = response.set_header('Permissions-Policy', 'interest-cohort=()')

  def after_sign_in_path_for(resource_or_scope)
    set_flash_message!(:alert, :warn_pwned) if resource.respond_to?(:pwned?) && resource.pwned?

    stored_location_for(resource_or_scope) || user_sign_in_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer
      .permit(
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
          time_zone_name
        ]
      )

    devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[email broker_customer_id first_name last_name phone])

    devise_parameter_sanitizer
      .permit(
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
        ]
      )
  end

  def global_controller? = false

  def last_modified_of(object)
    case object
    when ActiveRecord::Relation
      # The ETag's `cache_version` ("<count>-<:usec timestamp>") already queries MAX(updated_at), minding LIMIT and DISTINCT.
      timestamp = object.cache_version.split('-', 2).second
      Time.find_zone('UTC').strptime(timestamp, '%Y%m%d%H%M%S%N') if timestamp.present?
    when Enumerable then object.filter_map { last_modified_of(it) }.max
    else object.try(:updated_at)
    end
  end

  def sign_out_deactivated_user = (sign_out_and_redirect(current_user) if signed_in? && current_user.deactivated?)

  def stale?(*objects, etag: nil, last_modified: nil, **)
    if objects.any? { it.is_a?(Array) && it.any?(ActiveRecord::Base) }
      message = 'Passing an array to `stale?` loads every record into Ruby; pass each object as its own argument instead'
      raise message unless Rails.env.production?

      ActiveSupport.deprecator.warn(message, caller_locations)
    end

    # NOTE: Not `Array.wrap` or `flatten`: both call `to_ary`, which loads a relation.
    objects = objects.flat_map { it.is_a?(Array) ? it : [it] }.compact

    etag ||= objects.presence
    last_modified ||= objects.filter_map { last_modified_of(it) }.max

    super(etag:, last_modified:, **)
  end

  def storable_location? = request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  def store_user_location! = store_location_for(:user, request.fullpath)

  def user_sign_in_path
    return @user_sign_in_path = root_path unless current_user

    @user_sign_in_path = if current_user.customer?
                           customer_shipments_path
                         else
                           broker_shipments_path
                         end
  end
end
