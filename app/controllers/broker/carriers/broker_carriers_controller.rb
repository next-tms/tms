class Broker::Carriers::BrokerCarriersController < Broker::Carriers::BaseController
  include BrokerCarrierParameters

  before_action :set_broker_carrier, only: %i[edit show update]

  def create
    @broker_carrier = @carrier.broker_carriers.new(broker_carrier_params)
    @broker_carrier.ignore_bol_requires_tracking_number = Setting.ignore_broker_carrier_bol_requires_tracking_number(false)

    unless @broker_carrier.save
      render(:new, status: :unprocessable_content)
      return
    end

    redirect_to([:broker, @carrier, @broker_carrier])
  end

  def edit = @broker_carrier.find_or_build_check_mailing_address

  def index
    @q = @carrier.broker_carriers.includes(broker_customer: :customer).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'broker_customer_customer_name asc' if @q.sorts.blank?
    @pagy, @broker_carriers = pagy(@q.result)
  end

  def new = @broker_carrier = @carrier.broker_carriers.new(check_mailing_address: Address.new)
  def show; end

  def update
    @broker_carrier.assign_attributes(broker_carrier_params)

    unless @broker_carrier.save
      flash[:error] = t('.failure')
      render(:edit, status: :unprocessable_content)
      return
    end

    refresh_carrier_documents if @broker_carrier.api_configured? && credentials_changed?

    redirect_to([:broker, @carrier, @broker_carrier])
  end

  private

  def credentials_changed? = %i[account username password].any? { |attribute| @broker_carrier.saved_change_to_attribute?(attribute) }

  def refresh_carrier_documents
    shipments = @broker_carrier.shipments.where('created_at > ?', 90.days.ago)
    return if shipments.blank?

    TrackShipmentsJob.perform_later(shipments.pluck(:id))

    pending_delivery_shipment_ids = shipments.pending_delivery.pluck(:id)
    FetchShipmentCarrierBOLsJob.perform_later(pending_delivery_shipment_ids) if pending_delivery_shipment_ids.present?

    delivered_shipment_ids = shipments.delivered.pluck(:id)
    FetchShipmentCarrierPODsJob.perform_later(delivered_shipment_ids) if delivered_shipment_ids.present?
  end

  def set_broker_carrier = @broker_carrier = @carrier.broker_carriers.find(params.expect(:id))
end
