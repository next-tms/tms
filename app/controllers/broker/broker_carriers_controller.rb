# frozen_string_literal: true

class Broker::BrokerCarriersController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_broker_carrier, only: %i[contacts edit preferences search_terminals shipments show tariff update]

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

    @q.sorts = "#{Carrier.table_name + '.name'} desc" if @q.sorts.blank?
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
    if @broker_carrier.save
      redirect_to [:broker, @broker_carrier]
    else
      render :new
    end
  end

  def preferences; end

  def tariff
    if !@broker_carrier.carrier.carrier_areas.blank? && (!@broker_carrier.pricing_rules.size == @broker_carrier.carrier.carrier_areas.size)
      @broker_carrier.carrier.carrier_areas.each do |carrier_area|
        if @broker_carrier.pricing_rules.where(carrier_area: carrier_area).blank?
          @broker_carrier.pricing_rules << PricingRule.new(carrier_area: carrier_area)
        end
      end
    end
  end

  def search_terminals
    @terminals = Terminal.includes(:address).where('addresses.state ILIKE ?', params[:city]).where(
      'addresses.city ILIKE ?', params[:state]
    ).where(carrier: @broker_carrier.carrier).references(:address)
  end

  def update
    @broker_carrier.assign_attributes(broker_carrier_params)
    update_documents = @broker_carrier.will_save_change_to_account? || @broker_carrier.will_save_change_to_username? || @broker_carrier.will_save_change_to_password?

    if !@broker_carrier.save
      flash[:error] = 'Unable to update carrier'
      render :edit
    else
      if update_documents && @broker_carrier.api_configured?
        shipments = @broker_carrier.shipments.where('created_at > ?', 90.days.ago)
        unless shipments.blank?
          TrackShipmentsJob.perform_later(shipments.pluck(:id))

          pending_delivery_shipment_ids = shipments.pending_delivery.pluck(:id)
          unless pending_delivery_shipment_ids.blank?
            FetchShipmentCarrierBolsJob.perform_later(pending_delivery_shipment_ids)
          end

          delivered_shipment_ids = shipments.delivered.pluck(:id)
          FetchShipmentCarrierPodsJob.perform_later(delivered_shipment_ids) unless delivered_shipment_ids.blank?
        end
      end

      redirect_to [:broker, @broker_carrier]
    end
  end

  def contacts
    unauthorized if !current_user.broker == @broker_carrier.broker

    @q = @broker_carrier.contacts.ransack(params[:q])
    @q.sorts = 'contacts.first_name desc' if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def shipments
    unauthorized if !current_user.broker == @broker_carrier.broker

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
    params.require(:broker_carrier).permit(:id,
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
                                           :password,
                                           :username,
                                           :website_password,
                                           :website_username,
                                           check_mailing_address_attributes: %i[id ref street street2 city region_id
                                                                                zip_code],
                                           overlength_rules_attributes: %i[_destroy id max_length min_length cost],
                                           pricing_rules_attributes: %i[id carrier_area_id max_pallets min_pallets
                                                                        cost_per_pallet])
  end
end
