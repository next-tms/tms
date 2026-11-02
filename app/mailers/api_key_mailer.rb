class APIKeyMailer < ApplicationMailer
  helper :date_time

  def expiring
    @api_key = params[:api_key]
    @name = Setting.value!(:name)
    expires_at = l(@api_key.expires_at.in_time_zone(@api_key.authorizable.time_zone), format: :long)

    mail(
      from: "#{@name} <#{Setting.robot_email!}>",
      subject: t('.subject', expires_at:, name: @api_key.name),
      to: @api_key.authorizable.email
    )
  end
end
