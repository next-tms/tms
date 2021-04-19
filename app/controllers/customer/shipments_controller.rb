# frozen_string_literal: true

class Customer::ShipmentsController < Customer::CustomerController
  before_action :set_shipment_by_load_id, only: %i[book documents documents_bol documents_quote edit quote show unbook update]
  before_action :authenticate_user!

  def book
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = DateTime.current
    @shipment.save

    redirect_to [:customer, @shipment]
  end

  def unbook
    @shipment.updated_by = current_user
    @shipment.save

    @shipment.booked_at = nil
    @shipment.save

    redirect_to [:customer, @shipment]
  end

  def documents; end

  def documents_bol
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
    render 'shipments/documents_quote', layout: 'print'
  end

  def index
    @pagy, @shipments = pagy(current_user.broker_customer.shipments.active.order(created_at: :desc))
  end

  def new
    @shipment = Shipment.new
    @shipment.items << Item.new
    @shipment.shipper_address = Address.new
    @shipment.receiver_address = Address.new(country: current_user.broker_customer.primary_pickup_address.country)

    @shipment.shipper_contact_name = "#{current_user.first_name} #{current_user.last_name}"
    @shipment.shipper_name = current_user.broker_customer.customer.name

    unless current_user.broker_customer.primary_pickup_address.blank?
      @shipment.shipper_address = current_user.broker_customer.primary_pickup_address.dup
    end
  end

  def new_quote_only
    @shipment = Shipment.new
    @shipment.items << Item.new
    @shipment.shipper_address = Address.new
    @shipment.receiver_address = Address.new

    @shipment.shipper_contact_name = "#{current_user.first_name} #{current_user.last_name}"
  end

  def booked
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.broker_customer]).active.booked.order(:booked_at))
  end

  def create
    @shipment = Shipment.new(shipment_params)
    @shipment.updated_by = current_user
    @shipment.broker = current_user.broker
    @shipment.broker_customer = current_user.broker_customer
    @shipment.load_id = current_user.broker_customer.broker.last_load_id + 1
    if @shipment.save
      redirect_to quote_customer_shipment_path(@shipment) and return if current_user.broker_customer.can_quote?

      redirect_to [:customer, @shipment] and return
    else
      render :new
    end
  end

  def delivered
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.broker_customer).active.delivered.order(delivered_at: :desc))
  end

  def edit; end

  def show
    @shipment.update_tracking_events
  end

  def update
    @shipment.updated_by = current_user
    @shipment.save
    unless shipment_params[:applied_rate_uid].blank?
      @shipment.carrier_charge = current_user.broker_customer.carrier_charge_calculator(carrier_cost: @shipment.carrier_cost, shipment: @shipment)
    end
    if !@shipment.update(shipment_params)
      flash[:error] = "Unable to update shipment: #{@shipment.errors.full_messages.join(', ')}"
      redirect_back fallback_location: edit_customer_shipment_path(@shipment)
    else
      if !@shipment.shipper_address.full_address? || !@shipment.receiver_address.full_address?
        redirect_to edit_customer_shipment_path(@shipment) and return
      else
        redirect_to customer_shipment_path(@shipment) and return
      end
    end
  end

  def pending_delivery
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.broker_customer).active.pending_delivery.order(:picked_up_at))
  end

  def pending_dispatch
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.broker_customer).active.pending_dispatch.order(:created_at))
  end

  def pending_pickup
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.broker_customer).active.pending_pickup.distinct)
    # pending_pickup = Shipment.where(broker_customer: current_user.broker_customer).active.pending_pickup.distinct
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
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.broker_customer).active.pending_quotation.or(Shipment.where(broker_customer: current_user.broker_customer).canceled_recently).distinct.order(:created_at))
  end

  def quote
    @shipment.update_rates
    if current_user.broker_customer.always_show_quotes_based_on_calculated_classes?
      # calculated_freight_classes and forced_freight_classes are equal
      if !@shipment.rates.without_error.with_forced_freight_classes.blank? && @shipment.rates.without_error.with_calculated_freight_classes.blank?
        @rates = @shipment.rates.without_error.with_forced_freight_classes
      else
        @rates = @shipment.rates.without_error.with_calculated_freight_classes
      end
    else
      @rates = if @shipment.rates.without_error.with_forced_freight_classes.blank?
                 @shipment.rates.without_error.with_calculated_freight_classes
               else
                 @shipment.rates.without_error.with_forced_freight_classes
               end
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

  # Never trust parameters from the scary internet, only allow the white list through.
  def shipment_params
    params.require(:shipment).permit(:id,
                                     :applied_rate_uid,
                                     :bol_notes,
                                     :bol,
                                     :broker_carrier_id,
                                     :broker_customer_id,
                                     :broker_notes,
                                     :canceled_at,
                                     :carrier_id,
                                     :carrier_charge_encoded,
                                     :carrier_cost_encoded,
                                     :customer_notes,
                                     :customer_reference,
                                     :deliver_by,
                                     :delivered_at,
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
                                     :truckload,
                                     :value,
                                     shipper_address_attributes: %i[id ref street street2 city state zip_code country_id],
                                     receiver_address_attributes: %i[id ref street street2 city state zip_code country_id],
                                     items_attributes: %i[_destroy id packaging_id l w h nmfc forced_class hazmat refrigerated desc weight quantity],
                                     shipment_accessorials_attributes: %i[_destroy accessorial_id],
                                     shipment_broker_accessorials_attributes: %i[_destroy id broker_accessorial_id cost charge])
  end
end
