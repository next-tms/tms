# frozen_string_literal: true

class Broker::DelaysController < Broker::BrokerController
  before_action :set_delay, only: %i[edit show update]
  before_action :authenticate_user!

  def index; end

  def new
    @delay = Delay.new
  end

  def create
    @delay = Delay.new(delay_params)
    if @delay.save
      redirect_to [ :broker, @delay ]
    else
      render :new
    end
  end

  def edit; end

  def update
    @delay.updated_by = current_user
    @delay.save
    if !@delay.update(delay_params)
      flash[:error] = 'Unable to update delay'
      render :edit
    else
      redirect_to broker_delay_path(@delay)
    end
  end

  def show
    @delay.tracking unless @delay.delivered_at # Update tracking
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_delay
    @delay = Delay.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def delay_params
    params.require(:delay).permit(:id, :notes)
  end
end
