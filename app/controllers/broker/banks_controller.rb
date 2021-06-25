# frozen_string_literal: true

class Broker::BanksController < Broker::BrokerController
  before_action :set_bank, only: %i[activity show edit update destroy]
  before_action :authenticate_user!
  before_action :require_accounts_payable

  def activity
    @display_paid = ['0', nil].include?(params.dig(:q, :paid_on_null))

    @q = @bank.payments.paid.ransack(params[:q])
    @q.sorts = 'paid_on DESC' if @q.sorts.blank?
    @pagy, @payments = pagy(paid_or_pending_filter(@q))

    respond_to do |format|
      format.html
      format.csv do
        csv = ''.dup
        csv += "#{@payments.first.export_headers.join(',')}\n"
        csv += @payments.inject(''.dup) { |str, p| str << p.to_csv(false)  }
        send_data csv, filename: "#{@bank.pretty_name} Activity.csv"
      end
    end
  end

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
    if !@bank.update(bank_params)
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

  # Query helpers
  def paid_or_pending_filter(q)
    @display_paid ? q.result.paid : q.result.unpaid
  end

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
