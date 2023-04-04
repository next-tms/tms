# frozen_string_literal: true

class Customer::ShipmentsController < Customer::CustomerController
  include SuggestedShipmentAccessorials

  before_action :set_shipment_by_load_id, only: %i[book documents edit quote show unbook update]
  before_action :authenticate_user!

  def book
    redirect_to_edit = @shipment.quote_only?

    @shipment.update_columns(
      booked_at: Time.current,
      quote_only: false,
      updated_by_id: current_user.id,
    )

    if redirect_to_edit
      redirect_to(edit_customer_shipment_path(@shipment)) && return
    else
      redirect_to([:customer, @shipment])
    end
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
    @pagy, @shipments = pagy(current_user.companyable.shipments.active.includes(default_includes).order(created_at: :desc))
  end

  def new
    @shipment = Shipment.new

    # Needed for @shipment.broker_customer.eligible_broker_accessorials
    @shipment.broker_customer = current_user.companyable

    @shipment.items << Item.new
    @shipment.shipper_address = current_user.companyable&.primary_pickup_address&.dup || Address.new
    @shipment.receiver_address = Address.new

    @shipment.shipper_contact_name = "#{current_user.first_name} #{current_user.last_name}"
    @shipment.shipper_name = current_user.companyable.customer.name

    if current_user.companyable.primary_pickup_address.present?
      @shipment.shipper_address = current_user.companyable.primary_pickup_address.dup
    end
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
    @pagy, @shipments = pagy(Shipment.where(broker_customer: [current_user.companyable]).active.booked.order(:booked_at))
  end

  def create
    @shipment = Shipment.new(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.created_by = current_user
    @shipment.updated_by = current_user
    @shipment.broker = current_user.broker
    @shipment.broker_customer = current_user.companyable
    @shipment.load_id = current_user.companyable.broker.last_load_id + 1

    if shipment_params[:accessorials_has_been_suggested].blank?
      @shipment.shipper_address.find_or_build_standardized_address
      @shipment.receiver_address.find_or_build_standardized_address

      @accessorials_has_been_suggested = build_suggested_broker_accessorials(shipment: @shipment)
      render(:new) && return if @accessorials_has_been_suggested
    end

    if @shipment.save
      @shipment.refresh_documents!

      redirect_to(quote_customer_shipment_path(@shipment)) && return if current_user.companyable.can_quote?

      redirect_to([:customer, @shipment]) && return
    else
      render(:new)
    end
  end

  def delivered
    @pagy, @shipments = pagy(
      Shipment.where(broker_customer: current_user.companyable).active.delivered.includes(default_includes).order(delivered_at: :desc),
    )
  end

  def edit; end

  def show; end

  def update
    @shipment.assign_attributes(shipment_params.except(:accessorials_has_been_suggested))
    @shipment.updated_by = current_user

    if shipment_params[:applied_rate_uid].present?
      @shipment.carrier_charge = current_user.companyable.carrier_charge_calculator(
        carrier_cost: @shipment.carrier_cost, shipment: @shipment,
      )
    end

    respond_to do |format|
      if @shipment.save
        @shipment.refresh_documents!

        format.html { redirect_to(customer_shipment_path(@shipment)) }
        format.json { render(json: { location: customer_shipment_path(@shipment) }) }
      else
        format.html do
          flash[:error] = "Unable to update shipment: #{@shipment.errors.full_messages.join(", ")}"
          redirect_back(fallback_location: edit_customer_shipment_path(@shipment))
        end
        format.json { render(json: @shipment.errors, status: :unprocessable_entity) }
      end
    end
  end

  def pending_delivery
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.companyable).active.pending_delivery.order(:picked_up_at))
  end

  def pending_dispatch
    @pagy, @shipments = pagy(
      Shipment.where(broker_customer: current_user.companyable).active.pending_dispatch.includes(default_includes).order(:created_at),
    )
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
    @pagy, @shipments = pagy(Shipment.where(broker_customer: current_user.companyable).active.pending_quotation.or(Shipment.where(broker_customer: current_user.companyable).canceled_recently).distinct.order(:created_at))
  end

  def quote
    authorize! @shipment, to: :show?

    # TODO: Probably move this logic elsewhere
    reset = if @shipment.rates&.first&.shipment_fingerprint == @shipment.fingerprint
              false
            elsif @shipment.calculated_freight_classes.uniq == [nil] && @shipment.forced_freight_classes.uniq.nil?
              false
            elsif @shipment.broker_customer.preferred_broker_carriers_kind
              case @shipment.broker_customer.preferred_broker_carriers_kind
              when 'whitelist'
                (@shipment.broker_customer.eligible_broker_carriers.ids - @shipment.rates.pluck(:broker_carrier_id)).any?
              when 'blacklist'
                (@shipment.rates.pluck(:broker_carrier_id) - @shipment.broker_customer.eligible_broker_carriers.ids).any?
              end
            else
              true
            end

    reset = true if !reset && params[:force].present?

    if reset
      applied_rate = @shipment.applied_rate

      if @shipment.applied_rate.blank?
        @shipment.rates.destroy_all
      else
        @shipment.rates.where.not(id: @shipment.applied_rate.id).destroy_all
      end
    end

    @shipment.rates.where.not(error_object: nil).destroy_all

    broker_carrier_ids = []
    broker_carrier_ids += if @shipment.broker_customer.blank?
                            @shipment.broker.broker_carriers.blanket.api_configured.pluck(:id)
                          else
                            @shipment.broker_customer.eligible_broker_carriers.api_configured.pluck(:id)
                          end
    broker_carrier_ids += PricingRule.where(broker_carrier: @shipment.broker.broker_carriers).pluck(:broker_carrier_id)

    @broker_carriers = BrokerCarrier.where(id: broker_carrier_ids)

    @use_forced_freight_classes = if @shipment.forced_freight_classes.compact.sort == @shipment.calculated_freight_classes.compact.sort
                                    false
                                  else
                                    !@shipment.broker_customer.always_show_quotes_based_on_calculated_classes?
                                  end
  end

  private

  def default_includes
    [
      { shipper_address: :region },
      { receiver_address: :region },
      :shipment_items,
      :items,
    ]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  def set_shipment_by_load_id
    @shipment = Shipment.find_by(load_id: params[:load_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shipment_params
    params.require(:shipment).permit(
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
      shipper_address_attributes: %i[
                                    id
                                    ref
                                    street
                                    street2
                                    city
                                    region_id
                                    zip_code
                                    country_id
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
                                   ],
      items_attributes: %i[
                          _destroy
                          id
                          packaging_id
                          l
                          w
                          h
                          nmfc
                          forced_class
                          hazmat
                          refrigerated
                          desc
                          weight
                          quantity
                        ],
      shipment_accessorials_attributes: %i[_destroy accessorial_id],
      shipment_broker_accessorials_attributes: %i[
                                                 _destroy
                                                 id
                                                 broker_accessorial_id
                                                 cost
                                                 charge
                                               ],
    )
  end
end
