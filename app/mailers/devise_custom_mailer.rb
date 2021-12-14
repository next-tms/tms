# frozen_string_literal: true

class DeviseCustomMailer < Devise::Mailer
  def invitation_instructions(record, token, opts = {})
    opts[:from] = record.broker.robot_email

    super
  end
end
