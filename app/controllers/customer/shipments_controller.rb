class Customer::ShipmentsController < Customer::CustomerController
  include SuggestedShipmentAccessorials

  before_action :set_shipment_by_load_id, only: %i[book documents edit quote show unbook update]
  before_action :authenticate_user!

  def book
    redirect_to_edit = @shipment.quote_only?

    @shipment.update!(booked_at: Time.current, quote_only: false, updated_by_id: current_user.id)

    if redirect_to_edit
      redirect_to(edit_customer_shipment_path(@shipment))
      return
    end

    redirect_to([:customer, @shipment])
  end

  def unbook
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = nil
    @shipment.save

    redirect_to([:customer, @shipment])
  end

  def documents; end

  def index
    shipments = current_user.companyable.shipments.active.includes(default_includes).order(created_at: :desc)
    @pagy, @shipments = pagy(shipments)
  end

  def new
    @shipment = Shipment.new

    # Needed for @shipment.broker_customer.eligible_broker_accessorials
    @shipment.broker_customer = current_user.companyable

    @shipment.items << Item.new
    @shipment.shipper_address = current_user.companyable&.primary_pickup_address&.dup || Address.new
    @shipment.receiver_address = Address.new

    @shipment.shipper_contact_name = "#{current_user.first_name} #{current_user.last_name}"
    @shipment.shipper_address.name = current_user.companyable.customer.name
  end

  def new_quote_only
    @shipment = Shipment.new

    # Needed for @shipment.broker_customer.eligible_broker_accessorials
    @shipment.broker_customer = current_user.companyable

    @shipment.items << Item.new
    @shipment.shipper_address = Address.new
    @shipment.receiver_address = Address.new

    @shipment.shipper_contact_name = "#{current_user.first_name} #{current_user.last_name}"
  end

  def booked
    shipments = Shipment.where(broker_customer: [current_user.companyable]).active.booked.order(:booked_at)
    @pagy, @shipments = pagy(shipments)
  end

  def create
    @shipment = Shipment.new(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.created_by = current_user
    @shipment.updated_by = current_user
    @shipment.broker_customer = current_user.companyable

    @accessorials_has_been_suggested = build_suggested_broker_accessorials(shipment: @shipment).any?

    if @accessorials_has_been_suggested
      render(:new, status: :unprocessable_content)
      return
    end

    unless @shipment.save
      respond_to do |format|
        format.html { render(:new, status: :unprocessable_content) }
        format.json { render(:errors, locals: { record: @shipment }, status: :unprocessable_content) }
      end
      return
    end

    location = current_user.companyable.can_quote? ? [:quote, :customer, @shipment] : [:customer, @shipment]

    respond_to do |format|
      format.html { redirect_to(location) }
      format.json { render(:show, status: :created, location:) }
    end
  end

  def delivered
    shipments = Shipment
                .where(broker_customer: current_user.companyable)
                .active
                .delivered
                .includes(default_includes)
                .order(delivered_at: :desc)
    @pagy, @shipments = pagy(shipments)
  end

  def edit; end

  def show
    respond_to do |format|
      format.ebol do
        response.headers['Content-Disposition'] = ActionDispatch::Http::ContentDisposition.format(
          disposition: 'attachment',
          filename: "#{@shipment.load_id}.ebol.json"
        )

        stale?(
          @shipment,
          @shipment.broker_accessorials,
          @shipment.broker_carrier,
          @shipment.broker_carrier&.carrier,
          @shipment.broker_customer,
          @shipment.items,
          @shipment.receiver_address,
          @shipment.shipper_address
        )
      end
      format.html
    end
  end

  def update
    @shipment.assign_attributes(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.updated_by = current_user

    unless @shipment.save
      respond_to do |format|
        format.html { render(:edit, status: :unprocessable_content) }
        format.json { render(:errors, locals: { record: @shipment }, status: :unprocessable_content) }
      end
      return
    end

    location = [:customer, @shipment]

    respond_to do |format|
      format.html { redirect_to(location) }
      format.json { render(:location, locals: { location: }) }
    end
  end

  def pending_delivery
    shipments = Shipment.where(broker_customer: current_user.companyable).active.pending_delivery.order(:picked_up_at)
    @pagy, @shipments = pagy(shipments)
  end

  def pending_dispatch
    shipments = Shipment
                .where(broker_customer: current_user.companyable)
                .active
                .pending_dispatch
                .includes(default_includes)
                .order(:created_at)

    @pagy, @shipments = pagy(shipments)
  end

  def pending_pickup
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.companyable).active.pending_pickup.distinct)
    # pending_pickup = Shipment.where(broker_customer: current_user.companyable).active.pending_pickup.distinct
    #
    # @shipments_for_pickup_later = Shipment.none
    # @shipments_for_pickup_today = Shipment.none
    # @shipments_missed_pickup = Shipment.none
    #
    # pending_pickup.each do |shipment|
    #   if shipment.late?
    #     @shipments_missed_today += [shipment]
    #     next
    #   end
    #
    #   if shipment.pickup_by.blank?
    #     @shipments_for_pickup_today += [shipment]
    #     next
    #   end
    #
    #   if shipment.pickup_by >= shipment.shipper_address.time_zone.local_to_utc(Date.current.next_day.beginning_of_day)
    #     @shipments_for_pickup_later += [shipment]
    #   else
    #     @shipments_for_pickup_today += [shipment]
    #   end
    # end
  end

  def pending_quotation
    shipments = current_user
                .companyable
                .shipments
                .active
                .pending_quotation
                .or(
                  current_user
                  .companyable
                  .shipments
                  .canceled_recently
                )
                .distinct
                .order(:created_at)
    @pagy, @shipments = pagy(shipments)
  end

  def quote
    authorize!(@shipment, to: :manage?)

    Shipment::ResetRatesService.call(@shipment, force_reset: params[:force].present?)
    @shipment.rates.errored.destroy_all

    service = Shipment::FetchAndCreateRatesService
              .call(
                @shipment,
                user_type: current_user.type,
                shipment_fingerprint: @shipment.fingerprint
              )

    @declared_freight_classes = service.declared_freight_classes.first
    @rates_declared_freight_classes_false = service.rates_declared_freight_classes_false
    @rates_declared_freight_classes_true = service.rates_declared_freight_classes_true
    @populate_rate_jobs_on_queue = service.populate_rate_jobs_on_queue
  end

  private

  def default_includes
    %i[
      shipper_address
      receiver_address
      items
    ]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  def set_shipment_by_load_id
    @shipment = current_user.companyable.shipments.find_by!(load_id: params[:load_id])
  end

  def shipment_params
    params.expect(
      shipment: [
        :id,
        :accessorials_has_been_suggested,
        :applied_rate_uid,
        :bol_notes,
        :bol,
        :booked_at,
        :broker_carrier_id,
        :broker_customer_id,
        :broker_notes,
        :canceled_at,
        :carrier_id,
        :customer_notes,
        :customer_reference,
        :delivered_at,
        :delivery_appointment_on,
        :delivery_hours_end_at,
        :delivery_hours_start_at,
        :dispatched_at,
        :dispatched,
        :lift_gate,
        :out_for_delivery_at,
        :picked_up_at,
        :picked_up,
        :pickup_on,
        :pickup_confirmation,
        :pickup_hours_end_at,
        :pickup_hours_start_at,
        :priority,
        :pro,
        :promised_delivery_by,
        :quote_id,
        :quote_only,
        :quoted_delivery_by,
        :receiver_available_at,
        :receiver_contact_email,
        :receiver_contact_name,
        :receiver_contact_phone,
        :receiver_unavailable_at,
        :shipper_available_at,
        :shipper_contact_email,
        :shipper_contact_name,
        :shipper_contact_phone,
        :shipper_reference,
        :shipper_unavailable_at,
        :tracking_carrier_id,
        :truckload,
        :value,
        {
          shipper_address_attributes: %i[
            id
            name
            ref
            street
            street2
            city
            region_iso31662
            zip_code
            country_alpha2
          ],
          receiver_address_attributes: %i[
            id
            name
            ref
            street
            street2
            city
            region_iso31662
            zip_code
            country_alpha2
          ],
          items_attributes: [%i[
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
          ]],
          shipment_accessorials_attributes: [%i[_destroy accessorial_id]],
          shipment_broker_accessorials_attributes: [%i[
            _destroy
            id
            broker_accessorial_id
            cost
            charge
          ]]
        }
      ]
    )
  end
end
