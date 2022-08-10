# frozen_string_literal: true

class Broker::BrokerCarriersController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_broker_carrier, only: %i[
    contacts
    edit
    payments
    preferences
    search_terminals
    shipments
    show
    tariff
    terminals
    update
  ]

  def edit
    @broker_carrier.check_mailing_address = Address.new if @broker_carrier.check_mailing_address.blank?
  end

  def index
    @q = current_user
         .broker
         .broker_carriers
         .includes(
           [
             :broker_customer, { broker_customer: :customer },
             :carrier
           ]
         ).ransack(params[:q])

    @q.sorts = "#{Carrier.table_name.singularize}_name" if @q.sorts.blank?
    @pagy, @broker_carriers = pagy(@q.result)
  end

  def show
    if @broker_carrier.broker == current_user.broker
      @shipments = @broker_carrier.shipments.order(load_id: :desc).limit(25)
      @carrier_contacts = @broker_carrier.carrier.carrier_contacts
    else
      render file: 'public/401', layout: false, status: :unauthorized
    end
  end

  def new
    @broker_carrier = BrokerCarrier.new
    @broker_carrier.broker = current_user.broker
    @broker_carrier.check_mailing_address = Address.new
  end

  def create
    @broker_carrier = BrokerCarrier.new(broker_carrier_params)
    @broker_carrier.broker = current_user.broker
    @broker_carrier.ignore_bol_requires_tracking_number =
      current_user.broker.ignore_broker_carrier_bol_requires_tracking_number?

    redirect_to [:broker, @broker_carrier] and return if @broker_carrier.save

    render :new
  end

  def preferences; end

  def tariff
    return if @broker_carrier.carrier.carrier_areas.empty? ||
              @broker_carrier.pricing_rules.size == @broker_carrier.carrier.carrier_areas.size

    carrier_areas = @broker_carrier
                    .carrier
                    .carrier_areas
                    .where
                    .not(
                      id: @broker_carrier.pricing_rules.pluck(:carrier_area_id)
                    )

    return if carrier_areas.blank?

    carrier_areas.each do |carrier_area|
      next unless @broker_carrier.pricing_rules.where(carrier_area:).blank?

      @broker_carrier.pricing_rules.build(carrier_area:)
    end
  end

  def terminals
    unauthorized unless current_user.broker == @broker_carrier.broker

    @carrier = @broker_carrier.carrier

    @q = @carrier.terminals.ransack(params[:q])
    @pagy, @terminals = pagy(@q.result)
  end

  def search_terminals
    region_ids = Region
                 .where('name ILIKE ?', params[:state])
                 .or(Region.where('abbreviation ILIKE ?', params[:state]))
                 .ids

    @terminals = Terminal
                 .includes(:address)
                 .where(carrier_id: current_user.broker.carriers.ids)
                 .where('addresses.region_id IN (?)', region_ids)
                 .where('addresses.city ILIKE ?', params[:city])
                 .references(:address)
  end

  def update
    @broker_carrier.assign_attributes(broker_carrier_params)

    unless @broker_carrier.save
      flash[:error] = 'Unable to update carrier'
      render :edit and return
    end

    redirect_to [:broker, @broker_carrier] and return unless @broker_carrier.api_configured?

    update_documents = @broker_carrier.saved_change_to_account? ||
                       @broker_carrier.saved_change_to_username? ||
                       @broker_carrier.saved_change_to_password?

    redirect_to [:broker, @broker_carrier] and return unless update_documents

    shipments = @broker_carrier.shipments.where('created_at > ?', 90.days.ago)
    redirect_to [:broker, @broker_carrier] and return if shipments.blank?

    TrackShipmentsJob.perform_later(shipments.pluck(:id))

    pending_delivery_shipment_ids = shipments.pending_delivery.pluck(:id)
    FetchShipmentCarrierBolsJob.perform_later(pending_delivery_shipment_ids) unless pending_delivery_shipment_ids.blank?

    delivered_shipment_ids = shipments.delivered.pluck(:id)
    FetchShipmentCarrierPodsJob.perform_later(delivered_shipment_ids) unless delivered_shipment_ids.blank?

    redirect_to [:broker, @broker_carrier] and return
  end

  def contacts
    unauthorized unless current_user.broker == @broker_carrier.broker

    @q = @broker_carrier.contacts.ransack(params[:q])
    @q.sorts = 'contacts.first_name desc' if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def payments
    require_role('accounts_payable')

    @q = @broker_carrier
         .payments
         .includes(:payment_transactions)
         .ransack(params[:q])

    @q.sorts = 'due_on desc' if @q.sorts.blank?
    @pagy, @payments = pagy(@q.result)
  end

  def shipments
    unauthorized unless current_user.broker == @broker_carrier.broker

    @q = @broker_carrier
         .shipments
         .includes(
           :applied_rate,
           :items,
           :receiver_address,
           :tracking_carrier,
           :shipper_address
         ).ransack(params[:q])

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_carrier
    @broker_carrier = BrokerCarrier.find params[:id]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def broker_carrier_params
    params.require(:broker_carrier).permit(
      :id,
      :account_desc,
      :account,
      :accounting_notes,
      :broker_customer_id,
      :broker_id,
      :carrier_id,
      :create_invoice_on_pickup,
      :customer_id,
      :days_to_pay_after_invoice_date,
      :default_bol_notes,
      :ignore_bol_requires_tracking_number,
      :password,
      :username,
      :website_password,
      :website_username,
      check_mailing_address_attributes: %i[
        id
        ref
        country_id
        street
        street2
        city
        region_id
        zip_code
      ],
      overlength_rules_attributes: %i[
        _destroy
        id
        max_length
        min_length
        cost
      ],
      pricing_rules_attributes: %i[
        id
        carrier_area_id
        cost_per_pallet
        max_pallets
        min_pallets
      ]
    )
  end
end
