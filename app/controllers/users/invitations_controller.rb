# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  def create
    self.resource = invite_resource

    resource.update(
      broker: current_user.broker,
      time_zone_name: current_user.broker.time_zone_name
    )

    resource_invited = resource.errors.empty?

    yield resource if block_given?

    if resource_invited
      if is_flashing_format? && resource.invitation_sent_at
        set_flash_message :notice, :send_instructions, email: resource.email
      end
      if method(:after_invite_path_for).arity == 1
        respond_with resource, location: after_invite_path_for(current_inviter)
      else
        respond_with resource, location: after_invite_path_for(current_inviter, resource)
      end
    else
      respond_with_navigational(resource) { render :new }
    end
  end

  # Big hack for Safari autocompleting our hidden invitation_token field
  def update
    hacked_params = update_resource_params

    token_from_referer = unless request.headers['Referer'].blank?
                           Rack::Utils.parse_query(URI(request.headers['Referer']).query).dig('invitation_token')
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
      resource.invitation_token = hacked_params[:invitation_token]
      respond_with_navigational(resource) { render :edit }
    end
  end

  def after_invitation_accepted
    sign_in_path
  end

  def after_invite_path_for(_resource)
    broker_users_path
  end

  private

  def invite_resource
    super do |user|
      user.broker_id = current_user.broker_id
      user.time_zone_name = current_user.broker.time_zone_name
    end
  end
end
