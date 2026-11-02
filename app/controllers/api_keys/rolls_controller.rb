class APIKeys::RollsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_keys
  before_action :set_api_key

  def create
    authorize!(@api_key, to: :manage?)

    redirect_to(@api_key.roll!)
  end

  private

  def set_api_key = @api_key = @api_keys.active.find(params.expect(:api_key_id))
  def set_api_keys = @api_keys = authorized_scope(current_user.api_keys)
end
