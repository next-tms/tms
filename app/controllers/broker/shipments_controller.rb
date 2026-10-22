class Broker::ShipmentsController < Broker::BrokerController
  include SuggestedShipmentAccessorials

  before_action :set_shipment,
                only: %i[
                        accounting
                        book
                        book_modal
                        claims
                        create_tracking_event
                        destroy
                        documents
                        edit
                        edit_tracking_events
                        history
                        notes
                        pickup
                        pickup_modal
                        pricing
                        quote
                        send_document
                        send_document_with_contact_mailer
                        show
                        tracking_events
                        transit
                        unbook
                        update
                        update_transit
                        upload_document
                      ]
  before_action :authenticate_user!
  before_action :authorize_access_to_shipment,
                only: %i[
                        edit_tracking_events
                        quote
                        update
                        upload_document
                        show
                        tracking_events
                      ]

  def accounting
    authorize!(@shipment, to: :accounts_show?, with: DispatchAndSalesRepPolicy)

    @payment_transactions_q = @shipment.payment_transactions.ransack(params[:q], auth_object: current_user)
    @receivables_q = @shipment.receivables.ransack(params[:q], auth_object: current_user)
  end

  def book
    @shipment.update!(
      booked_at: Time.current,
      quote_only: false,
      updated_by_id: current_user.id,
    )

    if @shipment.quote_only?
      redirect_to(edit_broker_shipment_path(@shipment))
      return
    end

    redirect_to([ :broker, @shipment ])
  end

  def book_modal
    @applied_rate_uid = shipment_params[:applied_rate_uid] if params[:shipment].present?
    @broker_customers = current_user.broker_customers.includes(:customer).order('customers.name ASC')

    render(layout: 'modal')
  end

  def unbook
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = nil
    @shipment.save

    redirect_to([ :broker, @shipment ])
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def duplicate
    original_shipment = Shipment.find_by(load_id: params[:load_id])
    @shipment = Shipment::DuplicateService.new(shipment: original_shipment).call

    flash[:success] = "Duplicated from load ##{original_shipment.load_id}"
    redirect_to(edit_broker_shipment_path(@shipment))
  end

  def new
    @shipment = Shipment.new
    @shipment.items << Item.new

    @broker_customers = current_user.broker_customers.includes(:customer).order('customers.name')

    broker_customer = if params[:broker_customer_id].present?
                        BrokerCustomer.find_by(id: params[:broker_customer_id])
                      elsif current_user.broker_customers.size == 1
                        current_user.broker_customers.first
                      end

    @shipment.broker = Broker.first
    @shipment.broker_customer = broker_customer
    @shipment.dispatcher = current_user if current_user.role?(:dispatch) && !current_user.role?(:root)
    @shipment.receiver_address = Address.new
    @shipment.shipper_address = broker_customer&.primary_pickup_address&.dup || Address.new
    @shipment.shipper_name = broker_customer&.customer&.name

    @customer_dispatcher_ids = @broker_customers.map { |customer| customer.dispatchers.take&.id || 'n' }.join(',')
  end

  def new_quote_only
    @shipment = Shipment.new
    @shipment.items << Item.new
    @shipment.receiver_address = Address.new
    @shipment.shipper_address = Address.new
  end

  def create
    @broker_customers = current_user.broker_customers.includes(:customer).order('customers.name')

    Shipment.transaction do
      @shipment = Shipment.new(shipment_params.except(:accessorials_has_been_suggested))
      @shipment.lock! # Avoid race condition on Shipment#load_id

      @shipment.broker = current_user.broker
      @shipment.created_by = current_user
      @shipment.dispatcher ||= current_user if current_user.dispatcher_for?(@shipment)
      @shipment.load_id = Broker.first.last_load_id + 1
      @shipment.updated_by = current_user

      if !@shipment.quote_only? && shipment_params[:accessorials_has_been_suggested].blank?
        if @shipment.shipper_address.standardized_address.blank?
          @shipment.shipper_address.find_or_build_standardized_address
        end

        if @shipment.receiver_address.standardized_address.blank?
          @shipment.receiver_address.find_or_build_standardized_address
        end
      end
    end

    respond_to do |format|
      if @shipment.save
        location = [ :broker, @shipment ]

        format.html { redirect_to(location) }
        format.json { render(:show, status: :created, location:) }
      else
        format.html { render(:new, status: :unprocessable_entity) }
        format.json { render(json: @shipment.errors, status: :unprocessable_entity) }
      end
    end
  end

  def edit
    @broker_customers = current_user.broker_customers.includes(:customer).order('customers.name')
  end

  def update
    @shipment.assign_attributes(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.updated_by = current_user

    respond_to do |format|
      if @shipment.save
        format.html do
          if @shipment.dispatch_pickup
            redirect_to(broker_pickups_path(pickup: { rate_uid: @shipment.applied_rate.uid }))
          else
            flash[:success] = "#{Shipment.model_name.human.downcase.upcase_first} updated"
            redirect_to(broker_shipment_path(@shipment))
          end
        end
        format.json { render(json: { location: broker_shipment_path(@shipment) }) }
      else
        format.html { render(:edit, status: :unprocessable_entity) }
        format.json { render(json: @shipment.errors, status: :unprocessable_entity) }
      end
    end
  end

  def update_transit
    @shipment.assign_attributes(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.updated_by = current_user

    respond_to do |format|
      if @shipment.save
        location = transit_broker_shipment_path(@shipment)

        format.html do
          flash[:success] = "#{Shipment.model_name.human.downcase.upcase_first} updated"
          redirect_to(location)
        end
        format.json { render(:transit, status: :ok, location:) }
      else
        format.html { render(:transit, status: :unprocessable_entity) }
        format.json { render(json: @shipment.errors, status: :unprocessable_entity) }
      end
    end
  end

  def upload_document
    document_params = params.require(:shipment).permit(:document, :document_type)
    document = document_params[:document]

    blob = ActiveStorage::Blob.create_and_upload!(
      content_type: document.content_type,
      filename: document.original_filename,
      io: File.open(document),
    )

    @shipment.send(document_params[:document_type].to_sym).attach(blob)
    @shipment.problematic!

    flash[:success] = "Successfully uploaded document for Shipment ##{@shipment.load_id}"
    redirect_to(documents_broker_shipment_path(@shipment))
  end

  def show
    return unless @shipment.quote_only?

    redirect_to(quote_broker_shipment_path(@shipment))
  end

  def documents; end

  def send_document
    ids = @shipment.broker.contacts.ids

    if params[:shipment_method] != 'broker_quote' && @shipment.broker_carrier.present?
      ids += @shipment.broker_carrier.contacts.where(companyable: @shipment.broker_carrier).ids
    end

    if [ 'broker_dispatch_sheet', 'carrier_quote' ].none?(params[:shipment_method]) &&
       @shipment.broker_customer.present?
      ids += @shipment.broker_customer.contacts.where(companyable: @shipment.broker_customer).ids
    end

    @contacts = Contact.distinct.where(id: ids).order(:first_name)

    render(layout: 'modal')
  end

  def send_document_with_contact_mailer
    ContactMailer.send(
      params[:shipment_method].to_sym,
      from_user: current_user,
      to_contact: Contact.find(params[:contact_id]),
      shipment: @shipment,
    ).deliver_later

    render(layout: 'modal')
  end

  def destroy
    unless current_user.sales_rep_for?(@shipment.broker_customer) ||
           current_user.role?(:sales_rep_for_all_broker_customers)
      unauthorized
    end

    if current_user.broker == @shipment.broker
      if @shipment.destroy
        flash[:notice] = 'Shipment deleted'
      else
        flash[:danger] = 'Error deleting shipment'
        redirect_back(fallback_location: shipment_path(@shipment))
        return
      end
    else
      flash[:danger] = '403 Unauthorized'
    end

    redirect_to(shipments_path)
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
             { receiver_address: [ :region ] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             {
               broker_carrier: :carrier,
               broker_customer: :customer
             }
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
             { receiver_address: [ :region ] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             {
               broker_carrier: :carrier,
               broker_customer: :customer
             }
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
             { receiver_address: [ :region ] },
             { shipper_address: %i[region standardized_address] },
             {
               broker_carrier: :carrier,
               broker_customer: :customer
             }
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
             { receiver_address: [ :region ] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             {
               broker_carrier: :carrier,
               broker_customer: :customer
             }
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
           .canceled_recently,
         )
         .includes(
           [
             :items,
             { receiver_address: [ :region ] },
             { shipper_address: %i[region standardized_address] },
             :tracking_carrier,
             {
               broker_carrier: :carrier,
               broker_customer: :customer
             }
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
             { shipper_address: [ :region ] },
             { receiver_address: %i[region standardized_address] },
             :tracking_carrier,
             {
               broker_carrier: :carrier,
               broker_customer: :customer
             }
           ],
         )
         .ransack(params[:q], auth_object: current_user)
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
           ],
         )
         .ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.blank?

    @pagy, @shipments = pagy(@q.result)
  end

  def claims
    authorize!(@shipment, to: :accounts_and_claims_show?, with: DispatchAndSalesRepPolicy)

    @q = @shipment.claims.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @claims = pagy(@q.result)
  end

  def notes; end

  def pickup; end

  def pickup_modal
    @applied_rate_uid = shipment_params[:applied_rate_uid]

    render(layout: 'modal')
  end

  def pricing
    authorize!(@shipment, to: :accounts_show?, with: DispatchAndSalesRepPolicy)

    @total_charges_updated_by = @shipment.whodunnit('total_charges_cents')
  end

  def create_tracking_event
    @tracking_event = TrackingEvent.new(tracking_event_params)
    @tracking_event.shipment = @shipment
    if @tracking_event.save
      redirect_to(tracking_events_broker_shipment_path(@shipment))
    else
      render(:edit_tracking_events)
    end
  end

  def edit_tracking_events; end

  def tracking_events; end

  def transit
    authorize!(@shipment, to: :show?, with: DispatchAndSalesRepPolicy)
  end

  def transit_edit
    authorize!(@shipment, to: :show?, with: DispatchAndSalesRepPolicy)
  end

  def delivery; end

  def quote
    Shipment::ResetRatesService.call(@shipment, force_reset: params[:force].present?)
    @shipment.rates.errored.destroy_all

    service = Shipment::FetchAndCreateRatesService
              .call(
                @shipment,
                user_type: current_user.type,
                shipment_fingerprint: @shipment.fingerprint,
              )

    @declared_freight_classes = service.declared_freight_classes
    @rates_declared_freight_classes_false = service.rates_declared_freight_classes_false
    @rates_declared_freight_classes_true = service.rates_declared_freight_classes_true
    @populate_rate_jobs_on_queue = service.populate_rate_jobs_on_queue
  end

  def history
    @audits = @shipment.own_and_associated_audits.includes(:user)

    stale?(@shipment)
  end

  private

  def authorize_access_to_shipment
    authorize!(@shipment, to: :show?)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find_by!(load_id: params[:load_id])
  end

  def tracking_event_params
    params.require(:tracking_event).permit(
      :id,
      :at,
      :event_id,
      :time_zone,
      address_attributes: %i[id city region_id zip_code],
    )
  end

  def shipment_params
    params.require(:shipment).permit(
      :id,
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
      items_attributes: %i[
                          _destroy
                          id
                          packaging_id
                          l
                          w
                          h
                          nmfc
                          declared_freight_class
                          hazmat
                          refrigerated
                          desc
                          weight
                          quantity
                        ],
      receiver_address_attributes: %i[
                                     id
                                     ref
                                     street
                                     street2
                                     city
                                     region_id
                                     zip_code
                                     country_id
                                     standardized_address_id
                                   ],
      shipper_address_attributes: %i[
                                    id
                                    ref
                                    street
                                    street2
                                    city
                                    region_id
                                    zip_code
                                    country_id
                                    standardized_address_id
                                  ],
      shipment_accessorials_attributes: %i[_destroy accessorial_id],
      shipment_broker_accessorials_attributes: %i[
                                                 _destroy
                                                 id
                                                 broker_accessorial_id
                                                 cost
                                                 charge
                                               ],
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
                                  ],
    )
  end
end
