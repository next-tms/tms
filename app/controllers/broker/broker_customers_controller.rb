class Broker::BrokerCustomersController < Broker::BrokerController
  ALLOWED_ACCESS_FOR_ACCOUNTS_RECEIVABLE = ['show', 'shipments', 'update'].freeze
  ALLOWED_ACCESS_FOR_DISPATCHER = ['show', 'shipments'].freeze
  ALLOWED_ACCESS_FOR_SALES_REP = ['contacts'].freeze

  before_action :set_broker_customer, only: %i[
    broker_carriers
    contacts
    customer_contacts
    edit
    edit_broker_carriers
    edit_pricing
    preferences
    pricing
    primary_pickup_address
    receivables
    sales_reps
    shipments
    show
    update
    update_pricing
  ]
  before_action :authenticate_user!

  before_action :validate_user_role!, only: %i[update show contacts shipments]
  before_action :allow_sales_rep_or_accounts_receivable!, only: %i[edit edit_pricing]

  def accounting
    authorize!(current_user, to: :accounts_receivable_show?, with: AccountingPolicy)

    @broker_customers = BrokerCustomer.includes(required_includes).order('customers.name')

    @customers = Accounting.record_class(:customer).order(:display_name)
  end

  def broker_carriers
    @q = @broker_customer
         .broker_carriers
         .includes(
           [
             :broker_customer,
             { broker_customer: :customer },
             :carrier
           ]
         ).ransack(params[:q], auth_object: current_user)

    @q.sorts = "#{"#{Carrier.table_name}.name"} desc" if @q.sorts.blank?
    @pagy, @broker_carriers = pagy(@q.result)
  end

  def contacts
    @q = @broker_customer.contacts.ransack(params[:q], auth_object: current_user)
    @q.sorts = 'first_name asc' if @q.sorts.blank?
    @pagy, @contacts = pagy(@q.result)
  end

  def create
    @broker_customer = BrokerCustomer.new(broker_customer_params)

    # @broker_customer.sales_reps = [current_user]

    unless @broker_customer.save
      render(:new)
      return
    end

    flash[:success] = "#{@broker_customer.customer.name} saved. You may now edit pricing if you’d like."
    redirect_to([:edit_pricing, :broker, @broker_customer])
  end

  def customer_contacts; end

  def edit
    @broker_customer.primary_pickup_address = Address.new if @broker_customer.primary_pickup_address.blank?
  end

  def edit_broker_carriers; end

  def edit_pricing
    unauthorized unless current_user.role?(:account_payable) || current_user.sales_rep_for?(@broker_customer)
  end

  def index
    @q = current_user.broker_customers.includes(required_includes).ransack(params[:q], auth_object: current_user)

    @q.sorts = 'customer_name asc' if @q.sorts.blank?
    @pagy, @broker_customers = pagy(@q.result)
  end

  def new
    @broker_customer = BrokerCustomer.new
    @broker_customer.customer = Customer.new
    @broker_customer.office_address = Address.new
    @broker_customer.primary_pickup_address = Address.new
    @broker_customer.sales_reps = [current_user]
    @broker_customer.build_receivables_contact
  end

  def preferences
    unauthorized unless current_user.any_role?(['accounts_recevable', 'root']) ||
                        current_user.sales_rep_for?(@broker_customer)
  end

  def pricing; end

  # Used by Stimulus autofill_shipper
  def primary_pickup_address
    respond_to { |format| format.json { render(:primary_pickup_address) } }
  end

  def profitability_report
    unauthorized unless current_user.any_role?(:accounts_payable, :accounts_receivable)

    @broker_customers = BrokerCustomer.includes(:customer).order('customers.name ASC')

    @tz = ActiveSupport::TimeZone.new(Setting.time_zone_name!)
    @from_date = if params[:from_date].present?
                   @tz.parse(params[:from_date]).to_date
                 else
                   @tz.now.at_beginning_of_month.to_date
                 end
    @to_date = if params[:to_date].present?
                 @tz.parse(params[:to_date]).to_date
               else
                 @tz.now.at_end_of_month.to_date
               end
  end

  def receivables
    unauthorized unless current_user.role?(:accounts_receivable)

    @q = @broker_customer.receivables.ransack(params[:q], auth_object: current_user)

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @receivables = pagy(@q.result)
  end

  def sales_reps; end

  def shipments
    @q = @broker_customer
         .shipments
         .includes(
           :applied_rate,
           :broker_carrier,
           { broker_carrier: :carrier },
           :items,
           :receiver_address,
           :shipper_address,
           :tracking_carrier
         ).ransack(params[:q], auth_object: current_user)

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def show
    @shipments = @broker_customer.shipments.order(load_id: :desc).limit(25)

    respond_to do |format|
      format.html
      format.json { render(:primary_pickup_address) }
    end
  end

  def update_accounting
    authorize!(current_user, to: :accounts_receivable_show?, with: AccountingPolicy)

    unless BrokerCustomer.update(accounting_params.keys, accounting_params.values).all?(&:valid?)
      flash[:error] = t('.failure')
      redirect_to([:accounting, :broker, BrokerCustomer])
      return
    end

    flash[:success] = t('.success')
    redirect_to([:accounting, :broker, BrokerCustomer])
  end

  def update
    authorize!(@broker_customer, to: :accounts_receivable_show?, with: AccountsAndSalesRepPolicy)

    @broker_customer.assign_attributes(broker_customer_params)

    unless @broker_customer.save
      render(:edit)
      return
    end

    redirect_to([:broker, @broker_customer, @customer_contact])
  end

  def update_pricing
    authorize!(@broker_customer, to: :accounts_receivable_show?, with: AccountsAndSalesRepPolicy)

    unless @broker_customer.update(broker_customer_params)
      render(:edit_pricing)
      return
    end

    redirect_to([:edit_pricing, :broker, @broker_customer])
  end

  private

  def allow_sales_rep_or_accounts_receivable!
    authorize!(@broker_customer, to: :accounts_receivable_and_sales_rep_for_all_show?, with: AccountsAndSalesRepPolicy)
  end

  def not_sales_rep_for_all_and_broker_customer?
    !current_user.sales_rep_for?(@broker_customer) && !current_user.role?(:sales_rep_for_all_broker_customers)
  end

  def validate_user_role!
    return if current_user.role?(:root) ||
              (ALLOWED_ACCESS_FOR_DISPATCHER.include?(action_name) && current_user.dispatcher_only?) ||
              (ALLOWED_ACCESS_FOR_ACCOUNTS_RECEIVABLE.include?(action_name) && current_user.role?(:accounts_receivable))

    return if @broker_customer.present? && current_user.sales_rep_for?(@broker_customer)

    unauthorized if not_sales_rep_for_all_and_broker_customer?
  end

  def set_broker_customer
    @broker_customer = BrokerCustomer.find(params[:id])
  end

  def accounting_params = params.expect(accounting: { broker_customers: [%i[accounting_customer_id]] }).require(:broker_customers)

  def broker_customer_params
    params.expect(
      broker_customer: [
        :id,
        :always_show_quotes_based_on_calculated_classes,
        :customer_id,
        :can_quote,
        :default_upcharge,
        :default_upcharge_percentage,
        :default_bol_notes,
        :ignore_value_on_api_quotes,
        :internal_notes,
        :preferred_broker_carriers_kind,
        :receivables_contact_id,
        :receivables_schedule,
        :requires_carrier_bol_on_receivables,
        :requires_carrier_pod_on_receivables,
        :requires_shipment_delivery_before_receivable,
        :requires_charges_confirmed_on_receivables,
        :requires_customer_reference_number_on_receivables,
        :requires_shipment_shipper_reference_on_receivables,
        {
          preferred_broker_carriers_attributes: [%i[_destroy id broker_carrier_id]],
          broker_customer_sales_reps_attributes: [%i[_destroy id commission_flat commission_percent user_id]],
          broker_customer_dispatchers_attributes: [%i[_destroy id user_id]],
          accessorials_attributes: [%i[_destroy id code flat_charge name transponder_code upcharge upcharge_percent]],
          customer_attributes: %i[_destroy id legal_name name],
          document_preferences_attributes: [%i[_destroy id contact_id kind]],
          office_address_attributes: %i[id street street2 city region_iso31662 zip_code country_alpha2],
          primary_pickup_address_attributes: %i[id street street2 city region_iso31662 zip_code country_alpha2],
          receivables_contact_attributes: [
            :id,
            :first_name,
            :last_name,
            :label,
            :email,
            :_destroy,
            { contact_attributes: %i[id first_name last_name email] }
          ],
          upcharge_rules_attributes: [%i[_destroy id max min packaging_id upcharge upcharge_percentage]]
        }
      ]
    )
  end

  def required_includes
    %i[customer]
  end
end
