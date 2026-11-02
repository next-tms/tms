class APIKeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_keys
  before_action :set_api_key, only: %i[destroy show]

  etag { current_user && [@api_keys.active.ids, @api_keys.active.where(expires_at: ...APIKey::EXPIRES_SOON.from_now).ids] }

  def active = render_index(@api_keys.active)

  def create
    @api_key = @api_keys.new(api_key_params)
    authorize!(@api_key, to: :manage?)

    unless @api_key.save
      render(:new, status: :unprocessable_content)
      return
    end

    redirect_to(@api_key)
  end

  def destroy
    authorize!(@api_key, to: :manage?)

    @api_key.destroy!

    flash[:success] = t('.destroyed', model_name: APIKey.model_name.human, name: @api_key.name)
    redirect_to(APIKey)
  end

  def expired = render_index(@api_keys.expired)
  def index = render_index(@api_keys)

  def new
    @api_key = @api_keys.new(ttl: APIKey::MAX_TTL)
    authorize!(@api_key, to: :manage?)

    stale?(current_user)
  end

  def show
    authorize!(@api_key, to: :view?)

    stale?(@api_key)
  end

  private

  def api_key_params = params.expect(api_key: %i[name ttl])

  def render_index(api_keys)
    @q = api_keys.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @pagy, @api_keys = pagy(@q.result)

    render(:index) if stale?(@api_keys)
  end

  def set_api_key = @api_key = @api_keys.find(params.expect(:id))
  def set_api_keys = @api_keys = authorized_scope(current_user.api_keys)
end
