# frozen_string_literal: true

class Broker::SettingsController < Broker::BrokerController
  before_action do
    authenticate_user!
    require_role('accounts_payable')
  end

  before_action :set_setting, only: %i[company edit show update]

  def company
  end

  def create
    @setting = Setting.new(setting_params)

    redirect_to([:broker, @setting]) && return if @setting.save

    render(:new)
  end

  def edit; end

  def index
    @q = Setting.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'key asc' if @q.sorts.blank?

    @pagy, @settings = pagy(@q.result)
  end

  def new
    @setting = Setting.new
  end

  def show; end

  def update
    @setting.assign_attributes(setting_params)

    redirect_to(broker_settings_path) && return if @setting.save

    render(:edit)
  end

  private

  def set_setting
    @setting = Setting.find(params[:id])
  end

  def setting_params
    params.require(:setting).permit(:key, :value)
  end
end
