class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notifications
  before_action :set_notification, only: :show

  def index
    if params.dig(:q, :params_cont)
      ids = @notifications.select { |notification| notification.event.message.include?(params.dig(:q, :params_cont)) }.map(&:id)
      @notifications = @notifications.where(id: ids)
    end

    @pagy, @notifications = pagy(@notifications)

    stale?(@notifications)
  end

  def show
    authorize!(@notification, to: :view?)

    @notification.mark_as_read unless @notification.read?

    stale?(@notification)
  end

  private

  def set_notification = @notification = @notifications.find(params.expect(:id))
  def set_notifications = @notifications = authorized_scope(current_user.notifications.includes(:event).newest_first)
end
