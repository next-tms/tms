class Users::InvitationsController < Devise::InvitationsController
  before_action :authorize_invitation, only: %i[create]

  def new
    self.resource = resource_class.new(companyable_id: params[:companyable_id].presence,
                                       companyable_type: params[:companyable_type].presence,
                                       contact_id: params[:contact_id].presence)

    render :new
  end

  def create
    self.resource = invite_resource

    resource_invited = resource.errors.empty?

    yield resource if block_given?

    if resource_invited
      set_flash_message(:notice, :send_instructions, email: resource.email) if is_flashing_format? && resource.invitation_sent_at
      if method(:after_invite_path_for).arity == 1
        respond_with(resource, location: after_invite_path_for(current_inviter))
      else
        respond_with(resource, location: after_invite_path_for(current_inviter, resource))
      end
    else
      respond_with_navigational(resource) { render(:new) }
    end
  end

  # Big hack for Safari autocompleting our hidden invitation_token field
  def update
    hacked_params = update_resource_params

    token_from_referer = if request.headers['Referer'].present?
                           Rack::Utils.parse_query(URI(request.headers['Referer']).query)['invitation_token']
                         end

    if hacked_params[:invitation_token] == hacked_params[:email] && token_from_referer.present?
      hacked_params[:invitation_token] = token_from_referer
    end

    self.resource = resource_class.accept_invitation!(hacked_params)
    invitation_accepted = resource.errors.empty?

    yield resource if block_given?

    if invitation_accepted
      if resource.class.allow_insecure_sign_in_after_accept
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message(:notice, flash_message) if is_flashing_format?
        resource.after_database_authentication
        sign_in(resource_name, resource)
        respond_with(resource, location: after_accept_path_for(resource))
      else
        set_flash_message(:notice, :updated_not_active) if is_flashing_format?
        respond_with(resource, location: new_session_path(resource_name))
      end
    else
      resource.invitation_token = hacked_params[:invitation_token]
      respond_with_navigational(resource) { render(:edit) }
    end
  end

  def after_invitation_accepted
    sign_in_path
  end

  def after_invite_path_for(_inviter, invitee) = invitee.carrier? ? [:broker, invitee.companyable, User] : broker_users_path

  private

  def authorize_invitation
    authorize!(invitee, to: :create?, with: InvitationPolicy)

    existing_invitee = resource_class.find_by(email: invite_params[:email].to_s.strip.downcase)
    authorize!(existing_invitee, to: :create?, with: InvitationPolicy) if existing_invitee
  end

  def invite_resource
    super(&:build_contact)
  end

  def invitee = resource_class.new(invite_params.slice(:companyable_id, :companyable_type, :contact_id))
end
