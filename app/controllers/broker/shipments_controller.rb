# frozen_string_literal: true

class Broker::ShipmentsController < Broker::BrokerController
  before_action :set_shipment_by_load_id,
                only: %i[book book_modal rate_uid documents create_tracking_event destroy edit edit_tracking_events
                         notes pickup pickup_modal pricing quote send_document send_document_with_contact_mailer show
                         tracking_events transit unbook update]
  before_action :authenticate_user!

  def book
    redirect_to_edit = @shipment.quote_only?

    @shipment.update_columns(
      booked_at: DateTime.current,
      quote_only: false,
      updated_by_id: current_user.id
    )

    if redirect_to_edit
      redirect_to edit_broker_shipment_path(@shipment) and return
    else
      redirect_to [:broker, @shipment]
    end
  end

  def book_modal
    @applied_rate_uid = shipment_params[:applied_rate_uid] unless params[:shipment].blank?
    @broker_customers = current_user.broker_customers.includes(:customer).order('customers.name ASC')

    render layout: 'modal'
  end

  def unbook
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = nil
    @shipment.save

    redirect_to [:broker, @shipment]
  end

  def index
    @q = current_user.shipments.active.includes(required_includes).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def new
    @shipment = Shipment.new
    @shipment.items << Item.new

    broker_customer = nil
    broker_customer = BrokerCustomer.find_by_id(params[:broker_customer_id]) unless params[:broker_customer_id].blank?

    @shipment.shipper_name = broker_customer&.customer&.name
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
    @shipment.created_by = current_user
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

  def pickup; end

  def pickup_modal
    @applied_rate_uid = shipment_params[:applied_rate_uid]

    render layout: 'modal'
  end

  def update
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    @shipment.assign_attributes(shipment_params)
    @shipment.updated_by = current_user

    respond_to do |format|
      if @shipment.save
        format.html do
          if @shipment.dispatch_pickup
            redirect_to broker_pickups_path(pickup: { rate_uid: @shipment.applied_rate.uid }) and return
          else
            redirect_to broker_shipment_path(@shipment) and return
          end
        end
        format.json { render json: { location: broker_shipment_path(@shipment) } }
      else
        format.html do
          flash[:error] = "Unable to update shipment: #{@shipment.errors.full_messages.join(', ')}"
          redirect_back fallback_location: edit_broker_shipment_path(@shipment)
        end
        format.json { render json: @shipment.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    unless current_user.sales_rep_for?(@shipment.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end

    if @shipment.quote_only?
      redirect_to quote_broker_shipment_path(@shipment) and return
    else
      refresh_documents
    end
  end

  def documents
    refresh_documents
  end

  def send_document
    contact_ids = @shipment.broker.users.broker.pluck(:contact_id)

    if @shipment&.broker_customer&.contacts
      contact_ids += @shipment.broker_customer&.contacts&.where(broker_customer: @shipment&.broker_customer).pluck(:id)
    end

    if @shipment&.broker_carrier&.contacts
      contact_ids += @shipment.broker_carrier.contacts.where(broker_carrier: @shipment.broker_carrier).pluck(:id)
    end

    @contacts = Contact.distinct.where(id: contact_ids).order(:first_name)

    render layout: 'modal'
  end

  def send_document_with_contact_mailer
    ContactMailer.send(
      params[:shipment_method].to_sym,
      from_user: current_user,
      to_contact: Contact.find(params[:contact_id]),
      shipment: @shipment
    ).deliver_later

    render layout: 'modal'
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
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
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
    ).active.booked.includes([required_includes, :items, :receiver_address].flatten).ransack(params[:q])
    @q.sorts = 'booked_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_dispatch
    @q = current_user.shipments.active.pending_dispatch.includes([required_includes, :items,
                                                                  :receiver_address].flatten).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_delivery
    shipments = current_user.shipments.active.pending_delivery.includes(required_includes)

    @missing_delivery_eta_on_shipments = shipments.missing_delivery_eta_on
    unless @missing_delivery_eta_on_shipments.blank?
      shipments = shipments.where.not(id: @missing_delivery_eta_on_shipments.map(&:id))
    end

    @late_shipments = shipments.late.order(:picked_up_at)
    @shipments = shipments.not_late.order(:picked_up_at)
  end

  def pending_delivery; end

  def pending_delivery_late
    @q = current_user
         .shipments
         .active
         .pending_delivery
         .late
         .not_missing_delivery_eta_on
         .includes([required_includes, :receiver_address].flatten)
         .ransack(params[:q])

    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_delivery_on_time
    @q = current_user
         .shipments
         .active
         .pending_delivery
         .not_late
         .not_missing_delivery_eta_on
         .includes([required_includes, :receiver_address].flatten)
         .ransack(params[:q])

    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_delivery_without_delivery_eta_on
    @q = current_user
         .shipments
         .active
         .pending_delivery
         .missing_delivery_eta_on
         .includes([required_includes, :receiver_address].flatten)
         .ransack(params[:q])

    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_departure
    @q = current_user.shipments.active.pending_departure.includes([required_includes, :items,
                                                                   :receiver_address].flatten).ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_found
    @q = current_user.shipments.pending_found.includes(required_includes).ransack(params[:q])
    @q.sorts = 'created_at asc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def pending_pickup
    pending_pickup = current_user
                     .shipments
                     .active
                     .pending_pickup.includes([required_includes, :items, :receiver_address].flatten)

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
    ).includes([required_includes, :items, :receiver_address].flatten).ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result(distinct: true))
  end

  def delivered
    @q = current_user.shipments.active.delivered.includes(required_includes, :items,
                                                          :receiver_address).ransack(params[:q])
    @q.sorts = 'delivered_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def notes; end

  def pickup; end

  def pricing
    if !current_user.has_role?('accounting') && !current_user.has_role?('dispatch') && !current_user.sales_rep_for?(@shipment.broker_customer)
      unauthorized
    end
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
    unauthorized unless @shipment.accessible_by?(current_user)
  end

  def tracking_events
    unauthorized unless @shipment.accessible_by?(current_user)
  end

  def transit
    unauthorized unless @shipment.accessible_by?(current_user)
  end

  def transit_edit
    unauthorized unless @shipment.accessible_by?(current_user)
  end

  def delivery; end

  def quote
    unauthorized unless @shipment.accessible_by?(current_user)

    reset = if @shipment.rates&.first&.shipment_fingerprint == @shipment.fingerprint
              false
            elsif @shipment.calculated_freight_classes.uniq == [nil] && @shipment.forced_freight_classes.uniq.nil?
              false
            else
              true
            end

    reset = true if !reset && !params[:force].blank?

    if reset
      applied_rate = @shipment.applied_rate

      if @shipment.applied_rate.blank?
        @shipment.rates.destroy_all
      else
        @shipment.rates.where.not(id: @shipment.applied_rate.id).destroy_all
      end
    end

    broker_carrier_ids = []
    broker_carrier_ids += if @shipment.broker_customer.blank?
                            @shipment.broker.broker_carriers.blanket.api_configured.pluck(:id)
                          else
                            @shipment.broker_customer.eligible_broker_carriers.api_configured.pluck(:id)
                          end
    broker_carrier_ids += PricingRule.where(broker_carrier: @shipment.broker.broker_carriers).pluck(:broker_carrier_id)

    @broker_carriers = BrokerCarrier.where(id: broker_carrier_ids)

    calculated_freight_classes = @shipment.forced_freight_classes
    forced_freight_classes = @shipment.calculated_freight_classes

    if calculated_freight_classes.sort == forced_freight_classes.sort
      @use_forced_freight_classes = [false]
    else
      @use_forced_freight_classes = []
      @use_forced_freight_classes << false unless @shipment.calculated_freight_classes == [nil]
      @use_forced_freight_classes << true unless @shipment.forced_freight_classes == [nil]
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  def set_shipment_by_load_id
    @shipment = Shipment.find_by_load_id(params[:load_id])
  end

  def refresh_documents
    unless @shipment.broker_quote_valid?
      CreateShipmentBrokerQuoteJob.perform_later(
        domain: @website.homepage_domain,
        shipment: @shipment
      )
    end

    return if @shipment.incomplete?

    unless @shipment.broker_bol_valid?
      CreateShipmentBrokerBolJob.perform_later(
        domain: @website.homepage_domain,
        shipment: @shipment
      )
    end

    unless @shipment.broker_dispatch_sheet_valid?
      CreateShipmentBrokerDispatchSheetJob.perform_later(
        domain: @website.homepage_domain,
        shipment: @shipment
      )
    end

    FetchShipmentCarrierBolsJob.perform_later([@shipment.id]) if @shipment.carrier_bol.blank?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tracking_event_params
    params.require(:tracking_event).permit(:id,
                                           :at,
                                           :event_id,
                                           :time_zone,
                                           address_attributes: %i[id city region_id zip_code])
  end

  def shipment_params
    params.require(:shipment).permit(:id,
                                     :accessorial_codes,
                                     :applied_rate_uid,
                                     :bol_notes,
                                     :bol,
                                     :booked_at,
                                     :broker_carrier_id,
                                     :broker_customer_id,
                                     :broker_notes,
                                     :canceled_at,
                                     :carrier_id,
                                     :carrier_charge,
                                     :carrier_cost,
                                     :customer_notes,
                                     :customer_reference,
                                     :delivery_eta_on,
                                     :delivered_at,
                                     :delivery_appointment_at,
                                     :delivery_appointment_on,
                                     :delivery_hours_end_at,
                                     :delivery_hours_start_at,
                                     :departed_origin_terminal_at,
                                     :dispatch_pickup,
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
                                     :public_notes,
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
                                     receiver_address_attributes: %i[id ref street street2 city region_id zip_code
                                                                     country_id],
                                     shipper_address_attributes: %i[id ref street street2 city region_id zip_code
                                                                    country_id],
                                     shipment_accessorials_attributes: %i[_destroy accessorial_id],
                                     shipment_broker_accessorials_attributes: %i[_destroy id broker_accessorial_id
                                                                                 cost charge],
                                     tracking_events_attributes: [
                                       :_destroy,
                                       :id,
                                       :at,
                                       :city,
                                       :country_id,
                                       :event_id,
                                       :public,
                                       :region_id,
                                       { address_attributes: %i[id street street2 city region_id zip_code] }
                                     ])
  end

  # Query helpers
  def required_includes
    [
      :broker_carrier, { broker_carrier: :carrier },
      :broker_customer, { broker_customer: :customer },
      :applied_rate,
      :shipper_address,
      :tracking_carrier
    ]
  end
end
