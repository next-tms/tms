# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  # Big hack for Safari autocompleting our hidden invitation_token field
  def update
    hacked_params = update_resource_params

    token_from_referer = if !request.headers['Referer'].blank?
                           Rack::Utils.parse_query(URI(request.headers['Referer']).query).dig('invitation_token')
                         else
                           nil
                         end

    if hacked_params[:invitation_token] == hacked_params[:email] && !token_from_referer.blank?
      hacked_params[:invitation_token] = token_from_referer
    end

    self.resource = resource_class.accept_invitation!(hacked_params)
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      if resource.class.allow_insecure_sign_in_after_accept
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message :notice, flash_message if is_flashing_format?
        resource.after_database_authentication
        sign_in(resource_name, resource)
        respond_with resource, location: after_accept_path_for(resource)
      else
        set_flash_message :notice, :updated_not_active if is_flashing_format?
        respond_with resource, location: new_session_path(resource_name)
      end
    else
      resource.invitation_token = raw_invitation_token
      respond_with_navigational(resource) { render :edit }
    end
  end

  def after_invitation_accepted
    sign_in_path
  end

  def after_invite_path_for(resource)
    broker_users_path
  end

  private

  def invite_resource
    super { |user| user.broker_id = current_user.broker_id }
  end
end
