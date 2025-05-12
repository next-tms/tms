# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :set_notification_variables, only: %i[edit update]

  def update
    return super unless current_user.broker?

    blacklist = User.notification_types - (params[:email_notifications_blacklist] || [])
    current_user.update!(email_notifications_blacklist: blacklist.join(','))

    super
  end

  private

  def set_notification_variables
    @notification_types = User.notification_types
    @splitted_notification_types = @notification_types.each_slice(@notification_types.size / 2).to_a
    @blacklist = current_user.email_notifications_blacklist || []
  end
end
