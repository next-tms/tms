# frozen_string_literal: true

class Api::V1::Customer::ShipmentsController < Api::ApplicationController
  before_action :set_shipment_by_load_id, only: %i[quote show update]

  def create
    # Check permissions
    if current_user.broker_customer.blank?
      render json: { error: "Unauthorized: Wrong API endpoint: \"#{current_user.email}\" is not a customer of \"#{@website.broker.name}\"" }, status: :unauthorized and return
    elsif current_user.broker != @website.broker
      render json: { error: "Unauthorized: Wrong API endpoint: \"#{current_user.email}\" is not a user of \"#{@website.domain}\"" }, status: :unauthorized and return
    end
    unless current_user.broker_customer.can_quote?
      render json: { error: "Unauthorized: API not enabled for user \"#{current_user.email}\" of \"#{current_user.broker.name}\"" }, status: :unauthorized and return
    end

    @shipment = Shipment.new(
      {
        broker: current_user.broker,
        broker_customer: current_user.broker_customer,
        load_id: current_user.broker_customer.broker.last_load_id + 1,
        updated_by: current_user
      }.merge(shipment_params)
    )

    if @shipment.save
      @shipment.update_rates
      render json: @shipment, status: :ok and return
    else
      render json: { error: 'Unknown error', error_messages: @shipment.errors.full_messages.to_json }, status: :unprocessable_entity and return
    end
  end

  def quote
    # Check permissions
    if current_user.broker_customer.blank?
      render json: { error: "Unauthorized: Wrong API endpoint: \"#{current_user.email}\" is not a customer of \"#{@website.broker.name}\"" }, status: :unauthorized and return
    elsif current_user.broker != @website.broker
      render json: { error: "Unauthorized: Wrong API endpoint: \"#{current_user.email}\" is not a user of \"#{@website.domain}\"" }, status: :unauthorized and return
    end

    unless current_user.broker_customer.can_quote?
      render json: { error: "Unauthorized: API not enabled for user \"#{current_user.email}\" of \"#{current_user.broker.name}\"" }, status: :unauthorized and return
    end

    unless current_user.broker_customer == @shipment.broker_customer
      render json: { error: "Unauthorized: Shipment does not belong to \"#{current_user.email}\"" }, status: :unauthorized and return
    end

    @shipment.update_rates

    if @shipment.rates.blank?
      render json: {
        error: 'No rates found',
        shipment: {
          id: @shipment.load_id,
          accessorials: @shipment.accessorials,
          rates: nil
        }
      }.to_json, status: :unprocessable_entity and return
    else
      render json: { shipment: @shipment }.to_json, status: :ok and return
    end
  end

  def show
    render json: @shipment
  end

  def update
    @shipment.updated_by = current_user
    @shipment.save

    unless shipment_params[:applied_rate_uid].blank?
      @shipment.carrier_charge = current_user.broker_customer.carrier_charge_calculator(carrier_cost: @shipment.carrier_cost)
    end

    if @shipment.update(shipment_params)
      render json: @shipment, status: :ok and return
    else
      render json: { error: 'Unknown error', error_messages: @shipment.errors.full_messages.to_json }, status: :unprocessable_entity and return
    end
  end

  private

  def set_shipment_by_load_id
    @shipment = Shipment.find_by_load_id(params[:load_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
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
                                     shipper_address_attributes: %i[id ref street street2 city state zip_code],
                                     receiver_address_attributes: %i[id ref street street2 city state zip_code],
                                     items_attributes: %i[_destroy id packaging_id l w h nmfc forced_class hazmat refrigerated desc packaging_name weight quantity],
                                     shipment_accessorials_attributes: %i[_destroy accessorial_id],
                                     shipment_broker_accessorials_attributes: %i[_destroy id broker_accessorial_id cost charge],
                                     accessorial_codes: [])
  end
end
