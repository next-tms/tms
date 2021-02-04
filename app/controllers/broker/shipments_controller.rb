# frozen_string_literal: true

class Broker::ShipmentsController < Broker::BrokerController
  before_action :set_shipment_by_load_id,
                only: %i[rate_uid documents documents_bol documents_quote create_tracking_event destroy edit edit_tracking_events
                         notes pricing quote show tracking_events transit update]
  before_action :authenticate_user!

  def index; end

  def new
    @shipment = Shipment.new
    @shipment.items << Item.new

    broker_customer = BrokerCustomer.find_by_id(params[:broker_customer_id])
    @shipment.shipper_name = broker_customer.customer.name
    @shipment.broker_customer = broker_customer
    @shipment.shipper_address = broker_customer.primary_pickup_address.dup
    @shipment.receiver_address = Address.new
  end

  def new_quote_only
    @shipment = Shipment.new
    @shipment.items << Item.new
    @shipment.shipper_address = Address.new
    @shipment.receiver_address = Address.new
  end

  def create
    broker_customer = shipment_params[:broker_customer_id].blank? ? nil : BrokerCustomer.find(shipment_params[:broker_customer_id])
    @shipment = Shipment.new(shipment_params)
    @shipment.updated_by = current_user
    @shipment.broker = current_user.broker
    @shipment.broker_customer = broker_customer
    @shipment.load_id = current_user.broker.last_load_id + 1
    if @shipment.save
      if @shipment.quote_only?
        redirect_to quote_broker_shipment_path(@shipment)
      else
        redirect_to [:broker, @shipment]
      end
    else
      render :new
    end
  end

  def edit; end

  def update
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    @shipment.updated_by = current_user
    @shipment.save
    if !@shipment.update(shipment_params)
      flash[:error] = "Unable to update shipment: #{@shipment.errors.full_messages.join(', ')}"
      redirect_back fallback_location: edit_broker_shipment_path(@shipment)
    else
      redirect_to broker_shipment_path(@shipment)
    end
  end

  def show
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    if !@shipment.quote_only?
      @shipment.update_tracking_events
    else
      redirect_to quote_broker_shipment_path(@shipment)
    end
  end

  def documents; end

  def documents_bol
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    qrcode = RQRCode::QRCode.new(tracking_url(load_id: @shipment.load_id))
    @qrcode = qrcode.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 3,
      standalone: true,
      size: 150
    )
    render 'shipments/documents_bol', layout: 'print'
  end

  def documents_quote
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    render 'shipments/documents_quote', layout: 'print'
  end

  def destroy
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    if current_user.broker != @shipment.broker
      flash[:danger] = '403 Unauthorized'
    else
      @shipment.destroy
      flash[:notice] = 'Shipment deleted'
    end
    redirect_to shipments_path
  end

  def missing_delivery_appointment
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).missing_delivery_appointment)
  end

  def missing_pricing
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.missing_pricing.order(:created_at))
  end

  def missing_pro
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.missing_pro.order(:created_at))
  end

  def pending_dispatch
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_dispatch.order(:created_at))
  end

  def pending_delivery
    shipments = Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_delivery
    @late_shipments = shipments.late.order(:picked_up_at)
    @shipments = shipments.not_late.order(:picked_up_at)
  end

  def pending_departure
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_departure.order(:picked_up_at))
  end

  def pending_pickup
    pending_pickup = Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_pickup.or(Shipment.where(broker_customer: [current_user.broker_customers]).canceled_recently.pending_pickup).distinct

    @shipments_for_pickup_later = Shipment.none
    @shipments_for_pickup_today = Shipment.none
    @shipments_missed_pickup = Shipment.none

    pending_pickup.each do |shipment|
      if shipment.late?
        @shipments_missed_pickup += [shipment]
        next
      end

      if shipment.pickup_by.blank?
        @shipments_for_pickup_today += [shipment]
        next
      end

      pickup_by = shipment.pickup_by
      end_of_day = DateTime.current.end_of_day
      if pickup_by <= end_of_day
        @shipments_for_pickup_today += [shipment]
      else
        @shipments_for_pickup_later += [shipment]
      end
    end

    # @shipments_for_pickup_today = pending_pickup.where(pickup_on: nil).or(pending_pickup.where('pickup_on <= ?', Date.current)).distinct.order(:pickup_hours_end_at)
    # @shipments_for_pickup_later = pending_pickup.where('pickup_on > ?', Date.current).order(:pickup_hours_end_at)
  end

  def pending_quotation
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_quotation.or(Shipment.where(broker_customer: [current_user.broker_customers]).canceled_recently).distinct.order(:created_at))
  end

  def delivered
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.delivered.order(delivered_at: :desc))
  end

  def notes; end

  def pickup; end

  def pricing
    unauthorized if (!current_user.has_role? 'accounting') && !current_user.sales_rep_for?(@shipment.broker_customer)
  end

  def create_tracking_event
    @tracking_event = TrackingEvent.new(tracking_event_params)
    @tracking_event.shipment = @shipment
    if @tracking_event.save
      redirect_to tracking_events_broker_shipment_path(@shipment)
    else
      render :edit_tracking_events
    end
  end

  def edit_tracking_events
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@shipment.broker_customer)
  end

  def tracking_events
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@shipment.broker_customer)
  end

  def transit
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@shipment.broker_customer)
  end

  def transit_edit
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@shipment.broker_customer)
  end

  def delivery; end

  def quote
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@shipment.broker_customer)
    @shipment.update_rates
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  def set_shipment_by_load_id
    @shipment = Shipment.find_by_load_id(params[:load_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tracking_event_params
    params.require(:tracking_event).permit(:id,
                                           :at,
                                           :event_id,
                                           :time_zone,
                                           address_attributes: %i[id city state zip_code])
  end

  def shipment_params
    params.require(:shipment).permit(:id,
                                     :accessorial_codes,
                                     :applied_rate_uid,
                                     :bol_notes,
                                     :bol,
                                     :broker_carrier_id,
                                     :broker_customer_id,
                                     :broker_notes,
                                     :canceled_at,
                                     :carrier_id,
                                     :carrier_charge,
                                     :carrier_cost,
                                     :customer_notes,
                                     :customer_reference,
                                     :deliver_by,
                                     :delivered_at,
                                     :delivery_appointment_at,
                                     :delivery_appointment_on,
                                     :delivery_hours_end_at,
                                     :delivery_hours_start_at,
                                     :departed_origin_terminal_at,
                                     :dispatched_at,
                                     :dispatched,
                                     :lift_gate,
                                     :out_for_delivery_at,
                                     :pickup_driver_assigned_at,
                                     :picked_up_at,
                                     :picked_up,
                                     :pickup_eta_at,
                                     :pickup_on,
                                     :pickup_confirmation,
                                     :pickup_hours_end_at,
                                     :pickup_hours_start_at,
                                     :priority,
                                     :pro,
                                     :pending_appointment_since,
                                     :promised_delivery_by,
                                     :quote_id,
                                     :quote_only,
                                     :quoted_delivery_by,
                                     :receiver_available_at,
                                     :receiver_contact_email,
                                     :receiver_contact_name,
                                     :receiver_contact_phone,
                                     :receiver_name,
                                     :receiver_unavailable_at,
                                     :shipper_available_at,
                                     :shipper_contact_email,
                                     :shipper_contact_name,
                                     :shipper_contact_phone,
                                     :shipper_name,
                                     :shipper_reference,
                                     :shipper_unavailable_at,
                                     :tracking_carrier_id,
                                     :tracking_carrier_pickup_confirmation,
                                     :tracking_carrier_pro,
                                     :truckload,
                                     :value,
                                     items_attributes: %i[_destroy id packaging_id l w h nmfc forced_class hazmat
                                                          refrigerated desc weight quantity],
                                     receiver_address_attributes: %i[id ref street street2 city state zip_code],
                                     shipper_address_attributes: %i[id ref street street2 city state zip_code],
                                     shipment_accessorials_attributes: %i[_destroy accessorial_id],
                                     shipment_broker_accessorials_attributes: %i[_destroy id broker_accessorial_id
                                                                                 cost charge],
                                     tracking_events_attributes: [
                                       :_destroy,
                                       :id,
                                       :at,
                                       :city,
                                       :state,
                                       :country_alpha2,
                                       :event_id,
                                       :public,
                                       { address_attributes: %i[id street street2 city state zip_code] }
                                     ])
  end
end
