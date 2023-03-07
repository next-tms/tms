# frozen_string_literal: true

class Broker::BrokerCustomersController < Broker::BrokerController
  ALLOWED_ACCESS_FOR_DISPATCHER = ['show', 'shipments'].freeze
  ALLOWED_ACCESS_FOR_ACCOUNTS_RECEIVABLE = ['show', 'shipments', 'update'].freeze

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

  def broker_carriers
    @q = @broker_customer
         .broker_carriers
         .includes(
           [
             :broker_customer,
             { broker_customer: :customer },
             :carrier,
           ],
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

    # @broker_customer.sales_reps = [current_user]

    render(:new) && return unless @broker_customer.save

    flash[:success] = "#{@broker_customer.customer.name} saved. You may now edit pricing if you’d like."
    redirect_to(edit_pricing_broker_broker_customer_path(@broker_customer))
  end

  def customer_contacts; end

  def edit
    @broker_customer.primary_pickup_address = Address.new if @broker_customer.primary_pickup_address.blank?
  end

  def edit_broker_carriers; end

  def edit_pricing
    unauthorized unless current_user.any_roles?(['accounts_recevable', 'root']) ||
                        current_user.sales_rep_for?(@broker_customer)
  end

  def index
    @q = if current_user.any_role?(:accounts_recevable, :dispatch)
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
    @broker_customer.build_receivables_contact
  end

  def preferences
    unauthorized unless current_user.any_roles?(['accounts_recevable', 'root']) ||
                        current_user.sales_rep_for?(@broker_customer)
  end

  def pricing; end

  # Used by Stimulus autofill_shipper
  def primary_pickup_address
    respond_to do |format|
      format.json do
        if @broker_customer.broker == current_user.broker
          render(json: { primary_pickup_address: @broker_customer.primary_pickup_address })
        else
          head(:unauthorized)
        end
      end
    end
  end

  def profitability_report
    unauthorized unless current_user.any_role?(accounts_payable(accounts_receivable))

    @broker_customers = current_user.broker.broker_customers
    @from_date = Date.current.at_beginning_of_month
    @to_date = Date.current

    return if params[:from_date].blank?

    @from_date = Date.parse(params[:from_date])
    @to_date = params[:to_date].blank? ? Date.current : Date.parse(params[:to_date])
  end

  def quickbooks
    unauthorized && return unless current_user.broker? &&
                                  current_user.broker.intuit_account.present? &&
                                  current_user.role?(:accounts_receivable)

    @broker_customers = current_user
                        .broker
                        .broker_customers
                        .includes(required_includes)
                        .order('customers.name')

    @customers = QuickbooksAPIClient::Customers
                 .new(broker: current_user.broker)
                 .find_all
                 .sort_by(&:display_name)
  end

  def receivables
    unauthorized unless current_user.role?(:accounts_receivable)

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
           :broker_carrier,
           { broker_carrier: :carrier },
           :items,
           :receiver_address,
           :shipper_address,
           :tracking_carrier,
         ).ransack(params[:q])

    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  def show
    if @broker_customer.broker == current_user.broker
      @shipments = @broker_customer.shipments.order(load_id: :desc).limit(25)

      respond_to do |format|
        format.html
        format.json do
          render(json: { primary_pickup_address: @broker_customer.primary_pickup_address })
        end
      end
    else
      render(file: 'public/401', layout: false, status: :unauthorized)
    end
  end

  def update_quickbooks
    unauthorized && return unless current_user.broker? &&
                                  current_user.broker.intuit_account.present? &&
                                  current_user.role?(:accounts_receivable)

    broker = current_user.broker
    broker.assign_attributes(broker_params)

    if broker.save
      flash[:success] = 'QuickBooks customers updated'
      redirect_to(quickbooks_broker_broker_customers_path) && return
    end

    render(:quickbooks)
  end

  def update
    unauthorized unless current_user.any_roles?(['accounts_recevable', 'root']) ||
                        current_user.sales_rep_for?(@broker_customer)

    @broker_customer.assign_attributes(broker_customer_params)

    render(:edit) && return unless @broker_customer.save

    redirect_to([:broker, @broker_customer, @customer_contact])
  end

  def update_pricing
    unauthorized unless current_user.any_roles?(['accounts_recevable', 'root']) ||
                        current_user.sales_rep_for?(@broker_customer)

    render(:edit_pricing) && return unless @broker_customer.update(broker_customer_params)

    redirect_to(edit_pricing_broker_broker_customer_path(@broker_customer)) && return
  end

  private

  def allow_sales_rep_or_accounts_receivable!
    unauthorized if not_sales_rep_for_all_and_broker_customer? && !current_user.role?(:accounts_receivable)
  end

  def not_sales_rep_for_all_and_broker_customer?
    !current_user.sales_rep_for?(@broker_customer) && !current_user.role?(:sales_rep_for_all_broker_customers)
  end

  def validate_user_role!
    return if current_user.role?(:root) ||
              (ALLOWED_ACCESS_FOR_DISPATCHER.include?(action_name) && current_user.dispatcher_only?) ||
              (ALLOWED_ACCESS_FOR_ACCOUNTS_RECEIVABLE.include?(action_name) && current_user.role?(:accounts_receivable))

    unauthorized if not_sales_rep_for_all_and_broker_customer?
  end

  def set_broker_customer
    @broker_customer = BrokerCustomer.find(params[:id])
  end

  def broker_params
    params.require(:broker).permit(
      :id,
      broker_customers_attributes: %i[id quickbooks_customer_id],
    )
  end

  def broker_customer_params
    params.require(:broker_customer).permit(
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
      preferred_broker_carriers_attributes: %i[_destroy id broker_carrier_id],
      broker_customer_sales_reps_attributes: %i[_destroy id commission_flat commission_percent user_id],
      broker_customer_dispatchers_attributes: %i[_destroy id user_id],
      broker_accessorials_attributes: %i[_destroy id accessorial_id code flat_charge name upcharge upcharge_percent],
      customer_attributes: %i[_destroy id name],
      document_preferences_attributes: %i[_destroy id contact_id kind],
      office_address_attributes: %i[id street street2 city region_id zip_code country_id],
      primary_pickup_address_attributes: %i[id street street2 city region_id zip_code country_id],
      receivables_contact_attributes: [
                                        :id,
                                        :first_name,
                                        :last_name,
                                        :label,
                                        :email,
                                        :_destroy,
                                        { contact_attributes: %i[id first_name last_name email] },
                                      ],
      upcharge_rules_attributes: %i[_destroy id max min packaging_id upcharge upcharge_percentage],
    )
  end

  def required_includes
    %i[customer]
  end
end
