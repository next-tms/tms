# frozen_string_literal: true

class Broker::BanksController < Broker::BrokerController
  before_action :set_bank, only: %i[show edit update destroy]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def index
    @pagy, @banks = pagy(current_user.broker.banks.order(:name))
  end

  def new
    @bank = Bank.new
  end

  def create
    @bank = Bank.new(bank_params)
    @bank.broker = current_user.broker
    if @bank.save
      redirect_to [:broker, @bank]
    else
      render :new
    end
  end

  def edit; end

  def update
    if !@bank.update(contact_params)
      flash[:danger] = 'Unable to update contact'
      render :edit
    else
      redirect_to broker_banks_path
    end
  end

  def show
    unless @bank.broker == current_user.broker
      render file: 'public/401', layout: false, status: :unauthorized
    end
  end

  private

  def require_accounts_payable
    require_role 'accounts_payable'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_bank
    @bank = current_user.broker&.banks&.where(id: params[:id])&.first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bank_params
    params.require(:bank).permit(
      :id,
      :account_number,
      :name,
      :type_id
    )
  end
end
