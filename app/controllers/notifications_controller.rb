# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @notification = Notification.find(params[:id])
    @notification.mark_as_read!
  end

  def index
    notifications = current_user.notifications.newest_first

    if params.dig(:q, :params_cont)
      ids = notifications.select { |n| n.to_notification.message.include?(params.dig(:q, :params_cont)) }.map(&:id)
      notifications = current_user.notifications.where(id: ids).newest_first
    end

    @q = notifications.ransack({}, auth_object: current_user)
    @pagy, @notifications = pagy(@q.result)
  end
end
