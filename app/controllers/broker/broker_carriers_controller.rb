# frozen_string_literal: true

class Broker::BrokerCarriersController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_broker_carrier, only: %i[contacts edit preferences search_terminals shipments show tariff update]

  def edit
    @broker_carrier.check_mailing_address = Address.new if @broker_carrier.check_mailing_address.blank?
  end

  def index
    @broker_carriers = 

    @q = current_user.broker.broker_carriers.includes(:carrier).ransack(params[:q])
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
    if !@broker_carrier.carrier.carrier_areas.blank?
      if !@broker_carrier.pricing_rules.size == @broker_carrier.carrier.carrier_areas.size
        @broker_carrier.carrier.carrier_areas.each do |carrier_area|
          @broker_carrier.pricing_rules << PricingRule.new(carrier_area: carrier_area) if @broker_carrier.pricing_rules.where(carrier_area: carrier_area).blank?
        end
      end
    end
  end

  def search_terminals
    @terminals = Terminal.includes(:address).where('addresses.state ILIKE ?', params[:city]).where('addresses.city ILIKE ?', params[:state]).where(carrier: @broker_carrier.carrier).references(:address)
  end

  def update
    if !@broker_carrier.update(broker_carrier_params)
      flash[:error] = 'Unable to update carrier'
      render :edit
    else
      redirect_to [:broker, @broker_carrier]
    end
  end

  def contacts
    if !current_user.broker == @broker_carrier.broker
      unauthorized
    end

    @q = @broker_carrier.broker_carrier_contacts.includes(:contact).ransack(params[:q])
    @q.sorts = 'contacts.first_name desc' if @q.sorts.blank?
    @pagy, @broker_carrier_contacts = pagy(@q.result)
  end

  def shipments
    if !current_user.broker == @broker_carrier.broker
      unauthorized
    end

    @broker_carrier_carriers = BrokerCarrier.where broker: @broker_carrier.broker, carrier: @broker_carrier.carrier

    @q = @broker_carrier.shipments.ransack(params[:q])
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
                                           :accounting_notes,
                                           :broker_id,
                                           :broker_customer_id,
                                           :carrier_id,
                                           :customer_id,
                                           :create_invoice_on_pickup,
                                           :days_to_pay_after_invoice_date,
                                           :default_bol_notes,
                                           :account,
                                           :account_desc,
                                           :username,
                                           :password,
                                           check_mailing_address_attributes: %i[id ref street street2 city state zip_code],
                                           overlength_rules_attributes: %i[_destroy id max_length min_length cost],
                                           pricing_rules_attributes: %i[id carrier_area_id max_pallets min_pallets cost_per_pallet]
                                          )
  end
end
