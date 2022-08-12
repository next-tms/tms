class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @notification = Notification.find params[:id]
    @notification.mark_as_read!
  end

  def index
    @notifications = current_user.notifications.newest_first
  end
end
