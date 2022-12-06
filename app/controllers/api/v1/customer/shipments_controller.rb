# frozen_string_literal: true

class API::V1::Customer::ShipmentsController < API::ApplicationController
  before_action :set_shipment_by_load_id, only: %i[quote show update]

  def create
    # Check permissions and authority to quote
    render json: { error: unauthorized_error }, status: :unauthorized and return if unauthorized_error

    @shipment = Shipment.new(
      {
        broker: current_user.broker,
        broker_customer: current_user.broker_customer,
        load_id: current_user.broker_customer.broker.last_load_id + 1,
        updated_by: current_user
      }.merge(shipment_params)
    )

    unless @shipment.save
      render json: { error: 'Unknown error', error_messages: @shipment.errors.full_messages.to_json },
             status: :unprocessable_entity and return
    end

    @shipment.update_rates
    render json: @shipment, status: :ok and return
  end

  def quote
    # Check permissions and authority to quote
    render json: { error: unauthorized_error }, status: :unauthorized and return if unauthorized_error

    @shipment.update_rates

    render json: { shipment: @shipment }.to_json, status: :ok and return if @shipment.rates.present?

    render json: {
      error: 'No rates found',
      shipment: {
        id: @shipment.load_id,
        accessorials: @shipment.accessorials,
        rates: nil
      }
    }.to_json, status: :unprocessable_entity and return
  end

  def show
    render json: @shipment
  end

  def update
    @shipment.updated_by = current_user
    @shipment.save

    unless shipment_params[:applied_rate_uid].blank?
      @shipment.carrier_charge = current_user.broker_customer.carrier_charge_calculator(
        carrier_cost: @shipment.carrier_cost
      )
    end

    render json: @shipment, status: :ok and return if @shipment.update(shipment_params)

    render json: { error: 'Unknown error', error_messages: @shipment.errors.full_messages.to_json },
           status: :unprocessable_entity and return
  end

  private

  def unauthorized_error
    error = permission_error || customer_not_permitted_to_quote_error

    if current_user.broker_customer != @shipment.broker_customer && action_name == 'quote'
      error ||= "Unauthorized: Shipment does not belong to \"#{current_user.email}\""
    end

    error
  end

  def permission_error
    if current_user.broker_customer.blank?
      "Unauthorized: Wrong API endpoint: \"#{current_user.email}\" is not a customer of \"#{@website.broker.name}\""
    elsif current_user.broker != @website.broker
      "Unauthorized: Wrong API endpoint: \"#{current_user.email}\" is not a user of \"#{@website.domain}\""
    end
  end

  def customer_not_permitted_to_quote_error
    return if current_user.broker_customer.can_quote?

    "Unauthorized: API not enabled for user \"#{current_user.email}\" of \"#{current_user.broker.name}\""
  end

  def set_shipment_by_load_id
    @shipment = Shipment.find_by_load_id(params[:load_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # TODO: Move to a helper class that can be reused
  # rubocop:disable Metrics/MethodLength
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
                                     :customer_notes,
                                     :customer_reference,
                                     :delivery_eta_on,
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
                                     shipper_address_attributes: %i[id ref street street2 city region_id zip_code],
                                     receiver_address_attributes: %i[id ref street street2 city region_id zip_code],
                                     items_attributes: %i[_destroy id packaging_id l w h nmfc forced_class hazmat
                                                          refrigerated desc packaging_name weight quantity],
                                     shipment_accessorials_attributes: %i[_destroy accessorial_id],
                                     shipment_broker_accessorials_attributes: %i[_destroy id broker_accessorial_id cost
                                                                                 charge],
                                     accessorial_codes: [])
  end
  # rubocop:enable Metrics/MethodLength
end
