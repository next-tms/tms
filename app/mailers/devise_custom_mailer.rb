class DeviseCustomMailer < Devise::Mailer
  default from: -> { email_address_with_name(Setting.robot_email!, Setting.value!(:name)) }

  def invitation_instructions(record, token, opts = {})
    robot_email = Setting.robot_email!

    opts[:cc] = record.invited_by&.email.presence
    opts[:from] = robot_email
    opts[:reply_to] = record.invited_by&.email.presence || robot_email

    super
  end
end
