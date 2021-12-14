# frozen_string_literal: true

class DeviseCustomMailer < Devise::Mailer
  def invitation_instructions(record, token, opts = {})
    opts[:cc] = record.invited_by&.email
    opts[:from] = record.broker.robot_email
    opts[:reply_to] = record.invited_by&.email || record.broker.robot_email

    super
  end
end
