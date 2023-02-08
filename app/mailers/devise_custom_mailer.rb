# frozen_string_literal: true

class DeviseCustomMailer < Devise::Mailer
  def invitation_instructions(record, token, opts = {})
    robot_email = if record.broker?
                    record.companyable.robot_email
                  elsif record.customer?
                    record.companyable.broker.robot_email
                  end

    opts[:cc] = record.invited_by&.email.presence
    opts[:from] = robot_email
    opts[:reply_to] = record.invited_by&.email.presence || robot_email

    super
  end
end
