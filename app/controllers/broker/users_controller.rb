# frozen_string_literal: true

class Broker::UsersController < Broker::BrokerController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :authenticate_user!
  before_action :restrict_to_root

  def index
    @q = current_user.broker.users.includes(required_includes).ransack(params[:q])
    @q.sorts = 'contact.first_name desc' if @q.sorts.blank?

    @pagy, @users = pagy(@q.result)
  end

  private

  def restrict_to_root
    require_role('root')
  end

  # Query helpers
  def required_includes
    %i[contact]
  end
end
