class Broker::SettingsController < Broker::BrokerController
  before_action do
    authenticate_user!
    require_role('accounts_payable')
  end

  before_action :set_setting, only: %i[company edit show update]

  def company; end

  def create
    @setting = Setting.new(setting_params)

    unless @setting.save
      render(:new)
      return
    end

    redirect_to([:broker, @setting])
  end

  def edit; end

  def index
    @q = Setting.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'key asc' if @q.sorts.blank?

    @pagy, @settings = pagy(@q.result)
  end

  def new
    @setting = Setting.new(key: params[:key])
  end

  def show; end

  def update
    @setting.assign_attributes(setting_params)

    unless @setting.save
      render(:edit)
      return
    end

    redirect_to([:broker, Setting])
  end

  private

  def set_setting
    @setting = Setting.find(params[:id])
  end

  def setting_params
    params.expect(setting: [:key, :value, { address_attributes: %i[city country_alpha2 region_iso31662 street street2 zip_code] }])
  end
end
