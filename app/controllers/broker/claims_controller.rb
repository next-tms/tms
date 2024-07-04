# frozen_string_literal: true

class Broker::ClaimsController < Broker::BrokerController
  before_action :set_claim, only: %i[destroy edit show update]
  before_action :authenticate_user!
  before_action :require_claims

  def create
    @claim = Claim.new(claim_params)

    redirect_to([:broker, @claim]) and return if @claim.save

    render(:new)
  end

  def destroy
    @claim.destroy
    redirect_to(broker_claims_path)
  end

  def edit; end

  def index
    @q = Claim.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'due_on desc' if @q.sorts.blank?

    @pagy, @claims = pagy(@q.result)
  end

  def new
    @claim = Claim.new
    @claim.due_on = 90.days.from_now.in_time_zone(current_user.broker.time_zone).to_date
    @claim.shipment = current_user.broker.shipments.find_by(id: params[:shipment_id])

    @claim.claim_items.build(payee: @claim.shipment.broker_carrier, total: @claim.shipment.total_charges)

    return if @claim.shipment.present?

    flash[:error] = 'Cannot open a claim without a shipment'
    redirect_back(fallback_location: root_path)
  end

  def paid
    @q = Claim.paid.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @pagy, @claims = pagy(@q.result(distinct: true))
  end

  def unpaid
    @q = Claim.unpaid.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @pagy, @claims = pagy(@q.result(distinct: true))
  end

  def update
    redirect_to(broker_claim_path(@claim)) and return if @claim.update(claim_params)

    flash[:error] = 'Unable to update claim'
    render(:edit)
  end

  def show; end

  private

  def require_claims
    require_role('claims')
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_claim
    @claim = Claim.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def claim_params
    params.require(:claim).permit(
      :id,
      :broker_carrier_id,
      :due_on,
      :shipment_id,
      claim_items_attributes: %i[
                                _destroy
                                id
                                balance
                                payee_id
                                payee_type
                                total
                              ],
    )
  end

  def required_includes
    %i[claim_items shipment]
  end
end
