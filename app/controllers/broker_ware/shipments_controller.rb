class BrokerWare::ShipmentsController < BrokerWare::ApplicationController
  INCLUDES = [:receiver_address, :shipper_address, { broker_carrier: :carrier, items: :packaging }].freeze
  LANE_KEYS = { receiver_address: :consignee_zip, shipper_address: :shipper_zip }.freeze

  before_action :set_shipments
  before_action :set_shipment, only: %i[destroy update]

  rescue_from Date::Error, with: :render_bad_request

  wrap_parameters :shipment, format: :json, include: BrokerWare::ShipmentPayload::ROOT_KEYS

  def create
    rate = quoted_rate
    return if performed?

    @shipment = rate&.shipment || Shipment.new(broker_customer:)
    authorize!(@shipment, to: :create?)

    payload = BrokerWare::ShipmentPayload.new(rate ? shipment_params.except(:accessorials, :items) : shipment_params, shipment: @shipment)
    return unless valid_payload?(payload)

    if rate && lane_changed?
      render_error(t('broker_ware.shipments.lane_changed'), status: :bad_request)
      return
    end

    booking = { applied_rate_uid: rate&.uid, booked_at: Time.current, quote_only: false }.compact

    @shipment.assign_attributes(payload.shipment_attributes.merge(booking))
    @shipment.created_by = current_user if @shipment.new_record?
    save_shipment
  end

  def destroy
    authorize!(@shipment, to: :manage?)
    return unless before_pickup?

    cancel_shipment
  end

  def index
    authorize!(Shipment, to: :index?)

    @shipments = @shipments.where(created_at: date_range).order(:load_id)
    load_id = params[:load_id].presence || params[:loadid].presence
    @shipments = @shipments.where(load_id:) if load_id

    if params[:status].present?
      statuses = BrokerWare.statuses(params[:status])

      if statuses.empty?
        render_error(t('.unknown_status', status: params[:status]), status: :bad_request)
        return
      end

      @shipments = @shipments.where(status: statuses)
    end

    stale?(
      @shipments,
      Address.where(id: @shipments.select(:receiver_address_id)).or(Address.where(id: @shipments.select(:shipper_address_id))),
      Carrier.where(id: BrokerCarrier.where(id: @shipments.select(:broker_carrier_id)).select(:carrier_id)),
      Item.where(shipment: @shipments)
    )
  end

  def update
    authorize!(@shipment, to: :manage?)
    return unless before_pickup?

    payload = BrokerWare::ShipmentPayload.new(shipment_params, shipment: @shipment)
    return unless valid_payload?(payload)

    if payload.cancel?
      cancel_shipment
      return
    end

    if @shipment.applied_rate && lane_changed?
      render_error(t('broker_ware.shipments.lane_changed'), status: :bad_request)
      return
    end

    @shipment.assign_attributes(payload.shipment_attributes)
    save_shipment
  end

  private

  def before_pickup?
    return true if @shipment.picked_up_at.blank?

    render_error(t('broker_ware.shipments.picked_up'), status: :bad_request)
    false
  end

  def bookable?(rate)
    Shipment::QuotableRatesService.quotable?(rate, user_type: :customer) &&
      (rate.expires_at.blank? || rate.expires_at.future?) &&
      rate.shipment.booked_at.blank? &&
      rate.shipment.valid_broker_carriers_for_quotation(:customer).exists?(id: rate.broker_carrier_id)
  end

  def cancel_shipment
    Shipment.transaction do
      @shipment.update!(booked_at: nil, updated_by: current_user)
      @shipment.update!(canceled_at: Time.current)
    end

    render(:show)
  end

  def date_range = BrokerWare.date(params.require(:start_date)).beginning_of_day..BrokerWare.date(params.require(:end_date)).end_of_day

  def lane_changed?
    LANE_KEYS.any? do |address, key|
      shipment_params[key].present? && shipment_params[key].to_s.squish != @shipment.public_send(address)&.zip_code
    end
  end

  def quoted_rate
    rate_quote_id = shipment_params[:rate_quote_id]
    return if rate_quote_id.blank?

    rate = Rate.where(shipment: @shipments).find_by(uid: rate_quote_id)
    return rate if rate && bookable?(rate)

    render_error(t('broker_ware.shipments.unbookable_rate', rate_quote_id:), status: :bad_request)
    nil
  end

  def save_shipment
    @shipment.updated_by = current_user

    unless @shipment.save
      render_error(@shipment.errors.full_messages.to_sentence, status: :bad_request)
      return
    end

    render(:show)
  end

  def set_shipment = @shipment = @shipments.find_by!(load_id: require_param(shipment_params, :load_id))
  def set_shipments = @shipments = authorized_scope(Shipment.includes(INCLUDES))
  def shipment_params = @shipment_params ||= params.expect(shipment: BrokerWare::ShipmentPayload::PERMITTED).to_h.deep_symbolize_keys

  def valid_payload?(payload)
    return true if payload.valid?

    render_error(payload.errors.full_messages.to_sentence, status: :bad_request)
    false
  end
end
