class Broker::RatesController < Broker::BrokerController
  before_action :set_rate

  def breakdown_modal
    render layout: 'modal'
  end

  private

  def set_rate
    @rate = Rate.find_by(uid: params[:uid])
  end
end
