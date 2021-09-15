# frozen_string_literal: true

class Broker::ShipmentsController < Broker::BrokerController
  before_action :set_shipment_by_load_id,
                only: %i[book rate_uid documents documents_bol documents_quote create_tracking_event destroy edit edit_tracking_events
                         notes pricing quote show tracking_events transit unbook update]
  before_action :authenticate_user!

  def book
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = DateTime.current
    @shipment.save

    redirect_to [:broker, @shipment]
  end

  def unbook
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = nil
    @shipment.save

    redirect_to [:broker, @shipment]
  end

  def index
    @q = if current_user.roles.map(&:name).include?('sales_rep')
            broker_customer_ids = BrokerCustomerSalesRep.where(
              user: current_user
            ).pluck(:broker_customer_id)
        
            unless broker_customer_ids.blank?
              Shipment.active.where(broker_customer_id: broker_customer_ids).ransack(params[:q])
            else
              nil
            end
          else
            Shipment.active.includes(required_includes).ransack(params[:q])
          end

    if @q
      @q.sorts = 'created_at desc' if @q.sorts.blank?
      @pagy, @shipments = pagy(@q.result)
    else
      @pagy, @shipments = pagy(Shipment.none)
    end
  end

  def new
    @shipment = Shipment.new
    @shipment.items << Item.new

    broker_customer = BrokerCustomer.find_by_id(params[:broker_customer_id])
    @shipment.shipper_name = broker_customer.customer.name
    @shipment.broker_customer = broker_customer
    @shipment.shipper_address = broker_customer&.primary_pickup_address&.dup || Address.new
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

    respond_to do |format|
      if !@shipment.update(shipment_params)
        format.html do
          flash[:error] = "Unable to update shipment: #{@shipment.errors.full_messages.join(', ')}"
          redirect_back fallback_location: edit_broker_shipment_path(@shipment)
        end
        format.json { render json: @shipment.errors, status: :unprocessable_entity }
      else
        format.html { redirect_to broker_shipment_path(@shipment) }
        format.json { redirect_to broker_shipment_path(@shipment), status: :see_other }
      end
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
    @q = Shipment.where(broker_customer: [current_user.broker_customers]).missing_delivery_appointment.ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def missing_pricing
    @q = Shipment.where(broker_customer: [current_user.broker_customers]).active.missing_pricing.ransack(params[:q])
    @q.sorts = 'load_id asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def missing_pro
    @q = Shipment.where(broker_customer: [current_user.broker_customers]).active.missing_pro.ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def booked
    @q = Shipment.where(
      broker_customer_id: current_user.broker_customers.pluck(:id)
    ).active.booked.includes(required_includes).ransack(params[:q])
    @q.sorts = 'booked_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_dispatch
    @q = current_user.shipments.active.pending_dispatch.includes(required_includes).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_delivery
    shipments = current_user.shipments.active.pending_delivery.includes(required_includes)

    @missing_deliver_by_shipments = shipments.missing_deliver_by
    unless @missing_deliver_by_shipments.blank?
      shipments = shipments.where.not(id: @missing_deliver_by_shipments.map(&:id))
    end

    @late_shipments = shipments.late.order(:picked_up_at)
    @shipments = shipments.not_late.order(:picked_up_at)
  end

  def pending_departure
    @q = current_user.shipments.active.pending_departure.includes(required_includes).ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_found
    @q = current_user.shipments.pending_found.includes(required_includes).ransack(params[:q])
    @q.sorts = 'created_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_pickup
    pending_pickup = current_user.shipments.active.pending_pickup.includes(required_includes)

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

      if shipment.pickup_by >= shipment.shipper_address.time_zone.local_to_utc(Date.current.next_day.beginning_of_day)
        @shipments_for_pickup_later += [shipment]
      else
        @shipments_for_pickup_today += [shipment]
      end
    end
  end

  def pending_quotation
    @q = current_user.shipments.active.pending_quotation.or(
        current_user.shipments.canceled_recently
      ).includes(required_includes).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result(distinct: true))
  end

  def delivered
    @q = current_user.shipments.active.delivered.includes(required_includes).ransack(params[:q])
    @q.sorts = 'delivered_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
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

  def required_includes
    [
      { broker_carrier: :carrier },
      { broker_customer: :customer },
      :applied_rate,
      :items,
      :receiver_address,
      :shipper_address,
      :tracking_carrier
    ]
  end

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
                                     :lost_on,
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
                                     receiver_address_attributes: %i[id ref street street2 city state zip_code country_id],
                                     shipper_address_attributes: %i[id ref street street2 city state zip_code country_id],
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

  # Query helpers
  def required_includes
    [
      :broker_carrier, { broker_carrier: :carrier },
      :broker_customer, { broker_customer: :customer },
      :applied_rate,
      :items,
      :receiver_address,
      :shipper_address,
      :tracking_carrier
    ]
  end
end
