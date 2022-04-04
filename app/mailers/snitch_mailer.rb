# frozen_string_literal: true

class SnitchMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'

  def snitch(object_name, object_attributes, messages)
    messages = [message] unless messages.is_a?(Array)

    @caller = caller
    @messages = messages
    @object_attributes = object_attributes
    @object_name = object_name

    mail(to: ENV['DEVELOPER_EMAIL'], subject: "[next-tms/tms.next-tms.com] Report for #{object_name}")
  end
end
