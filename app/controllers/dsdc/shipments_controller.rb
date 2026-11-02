class DSDC::ShipmentsController < DSDC::ApplicationController
  INCLUDES = [
    :accessorials,
    :applied_rate,
    :carrier_pod_attachment,
    :receiver_address,
    :shipper_address,
    :tracking_carrier,
    { broker_carrier: :carrier, broker_customer: %i[customer office_address], items: :packaging, tracking_events: :event }
  ].freeze

  before_action :set_shipments
  before_action :set_shipment, only: %i[show]

  rescue_from Date::Error, with: :render_bad_request

  def index
    @shipments = @shipments
                 .where(broker_customer_id: params[:account_number])
                 .where(pickup_on: Date.iso8601(params[:start_date])..Date.iso8601(params[:end_date]))
                 .order(:load_id)

    if @shipments.empty?
      head(:no_content)
      return
    end

    broker_customers = BrokerCustomer.where(id: params[:account_number])

    stale?(
      @shipments,
      Address
        .where(id: @shipments.select(:receiver_address_id))
        .or(Address.where(id: @shipments.select(:shipper_address_id)))
        .or(Address.where(id: broker_customers.select(:office_address_id))),
      broker_customers,
      Carrier
        .where(id: BrokerCarrier.where(id: @shipments.select(:broker_carrier_id)).select(:carrier_id))
        .or(Carrier.where(id: @shipments.select(:tracking_carrier_id))),
      Customer.where(id: broker_customers.select(:customer_id)),
      Item.where(shipment: @shipments),
      TrackingEvent.where(shipment: @shipments)
    )
  end

  def show
    authorize!(@shipment, to: :view?)

    stale?(
      @shipment,
      @shipment.broker_carrier,
      @shipment.broker_carrier&.carrier,
      @shipment.broker_customer,
      @shipment.broker_customer&.customer,
      @shipment.broker_customer&.office_address,
      @shipment.carrier_pod_attachment,
      @shipment.items,
      @shipment.receiver_address,
      @shipment.shipper_address,
      @shipment.tracking_carrier,
      @shipment.tracking_events
    )
  end

  private

  def set_shipment
    @shipment = if params.key?(:pro)
                  @shipments.find_by!(load_id: params[:pro])
                elsif params.key?(:bol)
                  @shipments.shipped_from(params[:origin_postal_code]).find_by!(bol: params[:bol])
                else
                  @shipments.delivered_to(params[:destination_postal_code]).find_by!(customer_reference: params[:po])
                end
  end

  def set_shipments = @shipments = authorized_scope(Shipment.active.includes(INCLUDES))
end
