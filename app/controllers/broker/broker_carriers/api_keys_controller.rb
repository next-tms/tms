class Broker::BrokerCarriers::APIKeysController < Broker::BrokerCarriers::BaseController
  before_action :set_api_keys
  before_action :set_api_key, only: %i[destroy show]

  def create
    @api_key = @api_keys.new(api_key_params)
    authorize!(@api_key, to: :manage?)

    unless @api_key.save
      render(:new, status: :unprocessable_content)
      return
    end

    redirect_to([:broker, @broker_carrier, @api_key])
  end

  def destroy
    authorize!(@api_key, to: :manage?)

    @api_key.destroy!

    flash[:success] = t('.destroyed', model_name: APIKey.model_name.human, name: @api_key.name)
    redirect_to([:broker, @broker_carrier, APIKey])
  end

  def index
    @q = @api_keys.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @pagy, @api_keys = pagy(@q.result)

    stale?(@broker_carrier, @api_keys)
  end

  def new
    @api_key = @api_keys.new
    authorize!(@api_key, to: :manage?)

    stale?(@broker_carrier)
  end

  def show
    authorize!(@api_key, to: :view?)

    stale?(@broker_carrier, @api_key)
  end

  private

  def api_key_params = params.expect(api_key: %i[name])
  def set_api_key = @api_key = @api_keys.find(params.expect(:id))
  def set_api_keys = @api_keys = authorized_scope(@broker_carrier.api_keys)
end
