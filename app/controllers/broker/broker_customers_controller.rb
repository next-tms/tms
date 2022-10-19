# frozen_string_literal: true

class Broker::BrokerCustomersController < Broker::BrokerController
  ALLOWED_ACCESS_FOR_DISPATCHER = %w[show shipments].freeze
  ALLOWED_ACCESS_FOR_ACCOUNTS_RECEIVABLE = %w[show shipments update]

  before_action :set_broker_customer,
                only: %i[contacts edit edit_broker_carriers edit_pricing broker_carriers customer_contacts preferences pricing
                         primary_pickup_address receivables sales_reps shipments show update]
  before_action :authenticate_user!

  before_action :validate_user_role!, only: %i[update show contacts shipments]
  before_action :allow_sales_rep_or_accounts_receivable!, only: %i[edit edit_pricing]

  def broker_carriers
    @q = @broker_customer
         .broker_carriers
         .includes(
           [
             :broker_customer, { broker_customer: :customer },
             :carrier
           ]
         ).ransack(params[:q])

    @q.sorts = "#{"#{Carrier.table_name}.name"} desc" if @q.sorts.blank?
    @pagy, @broker_carriers = pagy(@q.result)
  end

  def contacts
    @q = @broker_customer.contacts.ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def create
    @broker_customer = BrokerCustomer.new(broker_customer_params)
    @broker_customer.broker = current_user.broker
    @broker_customer.primary_receivables_contact.broker = current_user.broker if @broker_customer.primary_receivables_contact
    # @broker_customer.sales_reps = [current_user]
    if @broker_customer.save
      flash[:success] = "#{@broker_customer.customer.name} saved. You may now edit pricing if you’d like."
      redirect_to edit_pricing_broker_broker_customer_path(@broker_customer)
    else
      render :new
    end
  end

  def customer_contacts; end

  def edit
    @broker_customer.primary_pickup_address = Address.new if @broker_customer.primary_pickup_address.blank?
  end

  def edit_broker_carriers; end

  def edit_pricing; end

  def index
    @q = if current_user.has_any_roles?(%w[accounts_recevable dispatch root])
           current_user.broker_customers.includes(required_includes).ransack(params[:q])
         else
           current_user.broker.broker_customers.includes(required_includes).ransack(params[:q])
         end

    @q.sorts = 'customer_name asc' if @q.sorts.blank?
    @pagy, @broker_customers = pagy(@q.result)
  end

  def new
    @broker_customer = BrokerCustomer.new
    @broker_customer.broker = current_user.broker
    @broker_customer.customer = Customer.new
    @broker_customer.office_address = Address.new
    @broker_customer.primary_pickup_address = Address.new
    @broker_customer.sales_reps = [current_user]
    @broker_customer.primary_receivables_contact = Contact.new
  end

  def preferences; end

  def pricing; end

  # Used by Stimulus autofill_shipper
  def primary_pickup_address
    respond_to do |format|
      format.json do
        if @broker_customer.broker == current_user.broker
          render json: { primary_pickup_address: @broker_customer.primary_pickup_address }
        else
          head :unauthorized
        end
      end
    end
  end

  def profitability_report
    unauthorized unless current_user.has_role? 'accounting'
    @broker_customers = current_user.broker.broker_customers
    @from_date = Date.current.at_beginning_of_month
    @to_date = Date.current

    return if params[:from_date].blank?

    @from_date = Date.parse(params[:from_date])
    @to_date = params[:to_date].blank? ? Date.current : Date.parse(params[:to_date])
  end

  def quickbooks
    unauthorized and return unless current_user.broker? &&
                                   current_user.broker.intuit_account.present? &&
                                   (current_user.has_role?('root') || current_user.has_role?('accounts_receivable'))

    @broker_customers = current_user
                        .broker
                        .broker_customers
                        .includes(required_includes)
                        .order('customers.name')

    @customers = QuickbooksApiClient::Customers
                 .new(broker: current_user.broker)
                 .find_all
                 .sort_by(&:display_name)
  end

  def receivables
    unauthorized unless current_user.has_role?('accounts_receivable')

    @q = @broker_customer
         .receivables
         .ransack(params[:q])

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def sales_reps; end

  def shipments
    @q = @broker_customer
         .shipments
         .includes(
           :applied_rate,
           :broker_carrier, { broker_carrier: :carrier },
           :items,
           :receiver_address,
           :shipper_address,
           :tracking_carrier
         ).ransack(params[:q])

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def show
    if @broker_customer.broker == current_user.broker
      @shipments = @broker_customer.shipments.order(load_id: :desc).limit(25)
      @customer_contacts = @broker_customer.customer.customer_contacts

      respond_to do |format|
        format.html
        format.json do
          render json: { primary_pickup_address: @broker_customer.primary_pickup_address }
        end
      end
    else
      render file: 'public/401', layout: false, status: :unauthorized
    end
  end

  def update_quickbooks
    unauthorized and return unless current_user.broker? &&
                                   current_user.broker.intuit_account.present? &&
                                   (current_user.has_role?('root') || current_user.has_role?('accounts_receivable'))

    broker = current_user.broker
    broker.assign_attributes(broker_params)

    if broker.save
      flash[:success] = 'QuickBooks customers updated'
      redirect_to quickbooks_broker_broker_customers_path and return
    end

    render :quickbooks
  end

  def update
    @broker_customer.assign_attributes(broker_customer_params)
    @broker_customer.sales_reps |= @broker_customer.sales_reps

    redirect_to [:broker, @broker_customer, @customer_contact] and return if @broker_customer.save

    flash[:danger] = 'Unable to update customer'
    render :edit
  end

  private

  def allow_sales_rep_or_accounts_receivable!
    unauthorized if not_sales_rep_for_all_and_broker_customer? && !current_user.has_role?('accounts_receivable')
  end

  def not_sales_rep_for_all_and_broker_customer?
    !current_user.sales_rep_for?(@broker_customer) && (!current_user.has_role? 'sales_rep_for_all_broker_customers')
  end

  def validate_user_role!
    return if ALLOWED_ACCESS_FOR_DISPATCHER.include?(action_name) && current_user.dispatcher_only?
    return if ALLOWED_ACCESS_FOR_ACCOUNTS_RECEIVABLE.include?(action_name) && current_user.has_role?('accounts_receivable')

    unauthorized if not_sales_rep_for_all_and_broker_customer?
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_customer
    @broker_customer = BrokerCustomer.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def broker_params
    params.require(:broker).permit(
      :id,
      broker_customers_attributes: %i[id quickbooks_customer_id]
    )
  end

  def broker_customer_params
    params.require(:broker_customer).permit(:id,
                                            :always_show_quotes_based_on_calculated_classes,
                                            :customer_id,
                                            :can_quote,
                                            :default_upcharge,
                                            :default_upcharge_percentage,
                                            :default_bol_notes,
                                            :ignore_value_on_api_quotes,
                                            :internal_notes,
                                            :preferred_broker_carriers_kind,
                                            :receivables_schedule,
                                            :requires_carrier_bol_on_receivables,
                                            :requires_carrier_pod_on_receivables,
                                            :requires_shipment_delivery_before_receivable,
                                            :requires_charges_confirmed_on_receivables,
                                            :requires_customer_reference_number_on_receivables,
                                            :requires_shipment_shipper_reference_on_receivables,
                                            preferred_broker_carriers_attributes: %i[
                                              _destroy
                                              id
                                              broker_carrier_id
                                            ],
                                            broker_customer_sales_reps_attributes: %i[
                                              _destroy
                                              id
                                              commission_flat
                                              commission_percent
                                              user_id
                                            ],
                                            broker_customer_dispatchers_attributes: %i[
                                              _destroy
                                              id
                                              user_id
                                            ],
                                            broker_accessorials_attributes: %i[
                                              _destroy
                                              id
                                              accessorial_id
                                              code
                                              flat_charge
                                              name
                                              upcharge
                                              upcharge_percent
                                            ],
                                            customer_attributes: %i[_destroy id name],
                                            document_preferences_attributes: %i[_destroy id contact_id kind],
                                            office_address_attributes: %i[
                                              id
                                              street
                                              street2
                                              city
                                              region_id
                                              zip_code
                                              country_id
                                            ],
                                            primary_pickup_address_attributes: %i[
                                              id
                                              street
                                              street2
                                              city
                                              region_id
                                              zip_code
                                              country_id
                                            ],
                                            primary_receivables_contact_attributes: %i[
                                              id
                                              email
                                              first_name
                                              last_name
                                            ],
                                            receivables_contacts_attributes: %i[
                                              id
                                              email
                                              first_name
                                              last_name
                                              _destroy
                                            ],
                                            upcharge_rules_attributes: %i[
                                              _destroy
                                              id
                                              max
                                              min
                                              packaging_id upcharge
                                              upcharge_percentage
                                            ])
  end

  def required_includes
    %i[customer]
  end
end
