# frozen_string_literal: true

class Broker::ShipmentsController < Broker::BrokerController
  include SuggestedShipmentAccessorials

  before_action :set_shipment_by_load_id,
                only: %i[
                  accounting book book_modal claims documents create_tracking_event destroy edit
                  edit_tracking_events notes pickup pickup_modal pricing quote rate_uid send_document
                  send_document_with_contact_mailer show tracking_events transit unbook update
                  history upload_document
                ]
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
    @q = current_user
         .shipments
         .includes(
           [
             :items,
             { shipper_address: :standardized_address },
             :tracking_carrier,
             { broker_carrier: :carrier },
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def new
    @shipment = Shipment.new
    @shipment.items << Item.new

    broker_customer = if params[:broker_customer_id].present?
                        BrokerCustomer.find_by_id(params[:broker_customer_id])
                      elsif current_user.broker_customers.size == 1
                        current_user.broker_customers.first
                      end

    # Only root can change the dispatcher on the form, so skip this unless current_user.has_role?('root')
    if current_user.has_role?('root')
      @shipment.broker = current_user.broker
      @shipment.dispatcher = if current_user.has_role?('dispatch')
                               current_user
                             else
                               @shipment.assign_dispatcher
                             end
    end

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
    Shipment.transaction do
      broker_customer = shipment_params[:broker_customer_id].blank? ? nil : BrokerCustomer.find(shipment_params[:broker_customer_id])
      @shipment = Shipment.new(shipment_params.except(:accessorials_has_been_suggested))
      @shipment.lock! # Avoid Race Condition

      @shipment.broker = current_user.broker
      @shipment.broker_customer = broker_customer
      @shipment.created_by = current_user
      @shipment.dispatcher = current_user if @shipment.dispatcher.blank? && current_user.dispatcher_for?(@shipment)
      @shipment.load_id = current_user.broker.last_load_id + 1
      @shipment.updated_by = current_user

      if shipment_params[:accessorials_has_been_suggested].blank?
        @shipment.shipper_address.find_or_build_standardized_address
        @shipment.receiver_address.find_or_build_standardized_address

        @accessorials_has_been_suggested = build_suggested_broker_accessorials(shipment: @shipment)
        render :new and return if @accessorials_has_been_suggested
      end

      if @shipment.save
        @shipment.refresh_documents!

        if @shipment.quote_only?
          redirect_to quote_broker_shipment_path(@shipment)
        else
          redirect_to [:broker, @shipment]
        end
      else
        render :new
      end
    end
  end

  def edit; end

  def update
    unauthorized and return unless @shipment.accessible_by?(current_user)

    @shipment.assign_attributes(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.updated_by = current_user

    respond_to do |format|
      if @shipment.save
        @shipment.refresh_documents!

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

  def upload_document
    unauthorized and return unless @shipment.accessible_by?(current_user)

    document_params = params.require(:shipment).permit(:document, :document_type)
    document = document_params[:document]

    blob = ActiveStorage::Blob.create_and_upload!(
      content_type: document.content_type,
      filename: document.original_filename,
      io: File.open(document)
    )

    @shipment.send(document_params[:document_type].to_sym).attach(blob)

    flash[:success] = "Successfully uploaded document for Shipment ##{@shipment.load_id}"
    redirect_to documents_broker_shipment_path(@shipment)
  end


  def show
    unauthorized and return unless @shipment&.accessible_by?(current_user)

    redirect_to quote_broker_shipment_path(@shipment) and return if @shipment.quote_only?
  end

  def documents; end

  def send_document
    contact_ids = @shipment.broker.users.broker.pluck(:contact_id)

    if @shipment&.broker_customer&.contacts
      contact_ids += @shipment.broker_customer&.contacts&.where(broker_customer: @shipment&.broker_customer)&.ids
    end

    if @shipment&.broker_carrier&.contacts
      contact_ids += @shipment.broker_carrier.contacts.where(broker_carrier: @shipment.broker_carrier).ids
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
    if current_user.broker == @shipment.broker
      @shipment.destroy
      flash[:notice] = 'Shipment deleted'
    else
      flash[:danger] = '403 Unauthorized'
    end

    redirect_to shipments_path
  end

  def missing_delivery_appointment
    @q = current_user
         .shipments
         .where(broker_customer_id: current_user.broker_customers.ids)
         .missing_delivery_appointment
         .includes(
           [
             { broker_carrier: :carrier },
             { shipper_address: %i[region standardized_address] },
             { receiver_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def missing_pricing
    @q = current_user
         .shipments
         .active
         .missing_pricing
         .includes(
           [
             :broker_carrier,
             :receiver_address,
             :shipper_address,
             :tracking_carrier,
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def missing_pro
    @q = current_user
         .shipments
         .active
         .missing_pro
         .includes(
           [
             :broker_carrier,
             :receiver_address,
             :shipper_address,
             :tracking_carrier,
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def booked
    @q = current_user
         .shipments
         .active
         .booked
         .includes(
           [
             :items,
             { receiver_address: [:region] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_carrier: :carrier,
               broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'booked_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def pending_dispatch
    @q = current_user
         .shipments
         .active
         .pending_dispatch
         .includes(
           [
             :items,
             { receiver_address: [:region] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_carrier: :carrier,
               broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def pending_delivery
    @q = current_user
         .shipments
         .active
         .pending_delivery
         .includes(
           [
             { broker_carrier: :carrier },
             { receiver_address: %i[region standardized_address] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'picked_up_at desc, promised_delivery_by desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def pending_departure
    @q = current_user
         .shipments
         .active
         .pending_departure
         .includes(
           [
             :items,
             { receiver_address: [:region] },
             { shipper_address: %i[region standardized_address] },
             { broker_carrier: :carrier,
               broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'picked_up_at asc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def pending_found
    @q = current_user
         .shipments
         .pending_found
         .includes(
           [
             :broker_carrier,
             :receiver_address,
             :shipper_address,
             :tracking_carrier,
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'created_at asc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def pending_pickup
    @q = current_user
         .shipments
         .active
         .pending_pickup
         .includes(
           [
             :items,
             { receiver_address: [:region] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_carrier: :carrier,
               broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'pickup_on' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def pending_quotation
    @q = current_user
         .shipments
         .active
         .pending_quotation
         .or(
           current_user
           .shipments
           .canceled_recently
         )
         .includes(
           [
             :items,
             { receiver_address: [:region] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_carrier: :carrier,
               broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result(distinct: true))
  end

  def delivered
    @q = current_user
         .shipments
         .active
         .delivered
         .includes(
           [
             :items,
             { shipper_address: [:region] },
             { receiver_address: %i[region standardized_address] },
             :tracking_carrier,
             { broker_carrier: :carrier,
               broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'delivered_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def as_dispatcher
    @q = current_user
         .shipments_as_dispatcher
         .active
         .includes(
           [
             :items,
             :receiver_address,
             :shipper_address,
             :tracking_carrier,
             { broker_carrier: :carrier },
             { broker_customer: :customer }
           ]
         )
         .ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def accounting
    if !current_user.has_role?('accounts_payable') && !current_user.has_role?('accounts_receivable') && !current_user.sales_rep_for?(@shipment.broker_customer) && !current_user.dispatcher_for?(@shipment)
      unauthorized
    end

    @payment_transactions_q = @shipment.payment_transactions.ransack(params[:q])
    @receivables_q = @shipment.receivables.ransack(params[:q])
  end

  def claims
    if !current_user.has_role?('claims') && !current_user.has_role?('accounts_payable') && !current_user.has_role?('accounts_receivable') && !current_user.sales_rep_for?(@shipment.broker_customer) && !current_user.dispatcher_for?(@shipment)
      unauthorized
    end

    @q = @shipment.claims.ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @claims = pagy(@q.result)
  end

  def notes; end

  def pickup; end

  def pickup_modal
    @applied_rate_uid = shipment_params[:applied_rate_uid]

    render layout: 'modal'
  end

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
    unauthorized and return unless @shipment.accessible_by?(current_user)
  end

  def tracking_events
    unauthorized and return unless @shipment.accessible_by?(current_user)
  end

  def transit
    unless current_user.has_role?('dispatch') || current_user.sales_rep_for?(@shipment.broker_customer)
      unauthorized and return
    end
  end

  def transit_edit
    unless current_user.has_role?('dispatch') || current_user.sales_rep_for?(@shipment.broker_customer)
      unauthorized and return
    end
  end

  def delivery; end

  def quote
    unauthorized and return unless @shipment.accessible_by?(current_user)

    # TODO: Probably move this logic elsewhere
    reset = if @shipment.rates&.first&.shipment_fingerprint == @shipment.fingerprint
              false
            elsif @shipment.calculated_freight_classes.uniq == [nil] && @shipment.forced_freight_classes.uniq.nil?
              false
            elsif @shipment.broker_customer.present? && @shipment.broker_customer.preferred_broker_carriers_kind
              case @shipment.broker_customer.preferred_broker_carriers_kind
              when 'whitelist'
                (@shipment.broker_customer.eligible_broker_carriers.ids - @shipment.rates.pluck(:broker_carrier_id)).any?
              when 'blacklist'
                (@shipment.rates.pluck(:broker_carrier_id) - @shipment.broker_customer.eligible_broker_carriers.ids).any?
              end
            else
              true
            end

    reset = true if !reset && !params[:force].blank?

    if reset
      if @shipment.applied_rate.blank?
        @shipment.rates.destroy_all
      else
        @shipment.rates.where.not(
          id: [@shipment.applied_rate.id] + @shipment.pickups.pluck(:rate_id)
        ).destroy_all
      end
    end

    @shipment.rates.where.not(error_object: nil).destroy_all

    broker_carrier_ids = []
    broker_carrier_ids += if @shipment.broker_customer.blank?
                            @shipment.broker.broker_carriers.blanket.api_configured.ids
                          else
                            @shipment.broker_customer.eligible_broker_carriers.api_configured.ids
                          end

    broker_carrier_ids += if @shipment.broker_customer.blank?
                            PricingRule
                              .where(broker_carrier: @shipment.broker.broker_carriers.blanket.api_unconfigured.ids)
                              .pluck(:broker_carrier_id)
                          else
                            PricingRule
                              .where(broker_carrier: @shipment.broker_customer.eligible_broker_carriers)
                              .pluck(:broker_carrier_id)
                          end

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

  def history
    @audits = @shipment.audits
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
                                           address_attributes: %i[id city region_id zip_code])
  end

  def shipment_params
    params.require(:shipment).permit(:id,
                                     :accessorial_codes,
                                     :accessorials_has_been_suggested,
                                     :applied_rate_uid,
                                     :bol_notes,
                                     :bol,
                                     :booked_at,
                                     :broker_and_broker_customer_notes,
                                     :broker_carrier_id,
                                     :broker_carrier_quote,
                                     :broker_customer_id,
                                     :broker_notes,
                                     :canceled_at,
                                     :carrier_bol,
                                     :carrier_charge,
                                     :carrier_cost,
                                     :carrier_id,
                                     :carrier_pod,
                                     :charges_confirmed,
                                     :customer_notes,
                                     :customer_reference,
                                     :delivered_at,
                                     :delivery_appointment_at,
                                     :delivery_appointment_on,
                                     :delivery_eta_on,
                                     :delivery_hours_end_at,
                                     :delivery_hours_start_at,
                                     :departed_origin_terminal_at,
                                     :dispatch_pickup,
                                     :dispatched_at,
                                     :dispatched,
                                     :dispatcher_id,
                                     :lift_gate,
                                     :lost_on,
                                     :out_for_delivery_at,
                                     :pending_appointment_since,
                                     :picked_up_at,
                                     :picked_up,
                                     :pickup_confirmation,
                                     :pickup_driver_assigned_at,
                                     :pickup_eta_at,
                                     :pickup_hours_end_at,
                                     :pickup_hours_start_at,
                                     :pickup_on,
                                     :priority,
                                     :pro,
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
end
