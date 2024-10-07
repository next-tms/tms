class Broker::BrokerCarriersController < Broker::BrokerController
  TERMINALS_FILTER = 'address_region_iso31662_or_address_city_or_address_street_or_address_zip_code_cont'.freeze

  before_action :authenticate_user!
  before_action :set_broker_carrier, except: %i[accounting create index new update_accounting]
  before_action :authorize_broker_carrier_access, only: %i[terminals contacts shipments]

  def accounting
    authorize!(current_user, to: :accounts_payable_show?, with: AccountingPolicy)

    @broker_carriers = BrokerCarrier.includes(required_includes).order('carriers.name')

    @vendors = Accounting.record_class(:vendor).order(:display_name)
  end

  def edit
    @broker_carrier.check_mailing_address = Address.new if @broker_carrier.check_mailing_address.blank?
  end

  def index
    @q = BrokerCarrier.includes(required_includes).ransack(params[:q], auth_object: current_user)

    @q.sorts = "#{Carrier.table_name.singularize}_name" if @q.sorts.blank?

    respond_with_export(@q.result)
  end

  def show
    @shipments = @broker_carrier.shipments.order(load_id: :desc).limit(25)
    @carrier_contacts = @broker_carrier.carrier.contacts
  end

  def new
    @broker_carrier = BrokerCarrier.new
    @broker_carrier.check_mailing_address = Address.new
  end

  def create
    @broker_carrier = BrokerCarrier.new(broker_carrier_params)
    @broker_carrier.ignore_bol_requires_tracking_number = Setting.ignore_broker_carrier_bol_requires_tracking_number(false)

    redirect_to([ :broker, @broker_carrier ]) && return if @broker_carrier.save

    render(:new)
  end

  def preferences; end

  def update_accounting
    authorize!(current_user, to: :accounts_payable_show?, with: AccountingPolicy)

    if BrokerCarrier.update(accounting_params.keys, accounting_params.values).all?(&:valid?)
      flash[:success] = 'Accounting vendors updated'
    else
      flash[:error] = 'Unable to update accounting vendors'
    end

    redirect_to(accounting_broker_broker_carriers_path)
  end

  def tariff; end

  def terminals
    @carrier = @broker_carrier.carrier

    @q = @carrier.terminals.ransack(terminals_query, auth_object: current_user)
    @pagy, @terminals = pagy(@q.result)
  end

  def search_terminals
    region_iso31662s = Transponder::ORM::Region
                       .all
                       .select { |region| [ region.abbreviation, region.name ].any? { |value| value.casecmp?(params[:state].to_s) } }
                       .map(&:iso31662)

    @terminals = Terminal
                 .includes(:address)
                 .where(carrier_id: BrokerCarrier.select(:carrier_id))
                 .where(addresses: { region_iso31662: region_iso31662s })
                 .where('addresses.city ILIKE ?', params[:city])
                 .references(:address)
  end

  def update
    @broker_carrier.assign_attributes(broker_carrier_params)

    unless @broker_carrier.save
      flash[:error] = 'Unable to update carrier'
      render(:edit) && return
    end

    redirect_to([ :broker, @broker_carrier ]) && return unless @broker_carrier.api_configured?

    update_documents = @broker_carrier.saved_change_to_account? ||
                       @broker_carrier.saved_change_to_username? ||
                       @broker_carrier.saved_change_to_password?

    redirect_to([ :broker, @broker_carrier ]) && return unless update_documents

    shipments = @broker_carrier.shipments.where('created_at > ?', 90.days.ago)
    redirect_to([ :broker, @broker_carrier ]) && return if shipments.blank?

    TrackShipmentsJob.perform_later(shipments.pluck(:id))

    pending_delivery_shipment_ids = shipments.pending_delivery.pluck(:id)
    FetchShipmentCarrierBOLsJob.perform_later(pending_delivery_shipment_ids) if pending_delivery_shipment_ids.present?

    delivered_shipment_ids = shipments.delivered.pluck(:id)
    FetchShipmentCarrierPODsJob.perform_later(delivered_shipment_ids) if delivered_shipment_ids.present?

    redirect_to([ :broker, @broker_carrier ]) && return
  end

  def update_tariff
    @broker_carrier.assign_attributes(tariff_params)

    unless @broker_carrier.save
      render(:tariff, status: :unprocessable_entity)
      return
    end

    flash[:success] = 'Tariff updated'
    redirect_to(tariff_broker_broker_carrier_path(@broker_carrier))
  end

  def contacts
    @q = @broker_carrier.contacts.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'contacts.first_name desc' if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def payment_transactions
    require_role('accounts_payable')

    @q = @broker_carrier
         .payment_transactions
         .ransack(params[:q], auth_object: current_user)

    @q.sorts = 'due_on desc' if @q.sorts.blank?
    @pagy, @payment_transactions = pagy(@q.result)
  end

  def payments
    require_role('accounts_payable')

    @q = @broker_carrier
         .payments
         .includes(:payment_transactions)
         .ransack(params[:q], auth_object: current_user)

    @q.sorts = 'due_on desc' if @q.sorts.blank?
    @pagy, @payments = pagy(@q.result)
  end

  def shipments
    @q = @broker_carrier
         .shipments
         .includes(
           :applied_rate,
           :items,
           :receiver_address,
           :tracking_carrier,
           :shipper_address,
         ).ransack(params[:q], auth_object: current_user)

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  private

  # Region names come from Transponder, so a filter that matches a region name also matches terminals in that region
  def terminals_query
    query = params[:q]&.to_unsafe_h.to_h
    filter = query.delete(TERMINALS_FILTER)
    return query if filter.blank?

    region_iso31662s = Transponder::ORM::Region.all.select { |region| region.name.downcase.include?(filter.downcase) }.map(&:iso31662)
    query.merge(g: [ { m: 'or', TERMINALS_FILTER => filter, address_region_iso31662_in: region_iso31662s } ])
  end

  def authorize_broker_carrier_access
    authorize!(@broker_carrier, to: :show?, with: BrokerPolicy)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_carrier
    @broker_carrier = BrokerCarrier.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def accounting_params = params.require(:accounting).permit(broker_carriers: %i[accounting_vendor_id]).require(:broker_carriers)

  def broker_carrier_params
    params
    .require(:broker_carrier)
    .permit(
      :id,
      :account_desc,
      :account,
      :accounting_notes,
      :broker_customer_id,
      :carrier_id,
      :create_invoice_on_pickup,
      :customer_id,
      :days_to_pay_after_invoice_date,
      :default_bol_notes,
      :encrypted_ach_account_number,
      :encrypted_ach_bank_name,
      :encrypted_ach_routing_number,
      :encrypted_api_key,
      :ignore_bol_requires_tracking_number,
      :password,
      :username,
      :website_password,
      :website_username,
      check_mailing_address_attributes: %i[
                                          id
                                          ref
                                          country_alpha2
                                          street
                                          street2
                                          city
                                          region_iso31662
                                          zip_code
                                        ],
    )
  end

  def required_includes
    [
      :carrier,
      :broker_customer,
      { broker_customer: :customer }
    ]
  end

  def tariff_params
    params
    .require(:broker_carrier)
    .permit(
      :id,
      overlength_rules_attributes: %i[_destroy cost id max_length min_length],
      pricing_rules_attributes: %i[_destroy id carrier_area_id cost_per_pallet max_pallets min_pallets],
    )
  end
end
