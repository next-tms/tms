# frozen_string_literal: true

class Broker::BrokerCustomersController < Broker::BrokerController
  before_action :set_broker_customer, only: %i[edit edit_broker_carriers edit_pricing broker_carriers customer_contacts preferences pricing primary_pickup_address sales_reps shipments show update]
  before_action :authenticate_user!

  def index
    @q = if current_user.sales_rep_only?
           current_user.broker_customers
         else
           current_user.broker.broker_customers
         end.ransack(params[:q])
    @q.sorts = "#{Customer.table_name + '.name'} desc" if @q.sorts.blank?
    @pagy, @broker_customers = pagy(@q.result)
  end

  def profitability_report
    unauthorized unless current_user.has_role? 'accounting'
    @broker_customers = current_user.broker.broker_customers
    @from_date = Date.current.at_beginning_of_month
    @to_date = Date.current
    unless params[:from_date].blank?
      @from_date = Date.parse(params[:from_date])
      @to_date = params[:to_date].blank? ? Date.current : Date.parse(params[:to_date])
    end
  end

  def edit_broker_carriers; end

  def broker_carriers; end

  def customer_contacts; end

  def edit_pricing; end

  def preferences; end

  def pricing; end

  def sales_reps; end

  def new
    @broker_customer = BrokerCustomer.new
    @broker_customer.broker = current_user.broker
    @broker_customer.customer = Customer.new
    @broker_customer.primary_pickup_address = Address.new
    @broker_customer.sales_reps = [current_user]
  end

  def create
    @broker_customer = BrokerCustomer.new(broker_customer_params)
    @broker_customer.broker = current_user.broker
    # @broker_customer.sales_reps = [current_user]
    if @broker_customer.save
      redirect_to [:broker, @broker_customer]
    else
      render :new
    end
  end

  def edit
    if !current_user.sales_rep_for?(@broker_customer) && (!current_user.has_role? 'sales_rep_for_all_broker_customers')
      unauthorized
    end
    @broker_customer.primary_pickup_address = Address.new if @broker_customer.primary_pickup_address.blank?
  end

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

  def update
    if !current_user.sales_rep_for?(@broker_customer) && (!current_user.has_role? 'sales_rep_for_all_broker_customers')
      unauthorized
    end
    if !@broker_customer.update(broker_customer_params)
      Rails.logger.debug(@broker_customer.errors)
      flash[:danger] = 'Unable to update customer'
      render :edit
    else
      @broker_customer.sales_reps |= @broker_customer.sales_reps
      @broker_customer.save
      redirect_to [:broker, @broker_customer, @customer_contact]
    end
  end

  def show
    if !current_user.sales_rep_for?(@broker_customer) && (!current_user.has_role? 'sales_rep_for_all_broker_customers')
      unauthorized
    end
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

  def shipments
    if !current_user.sales_rep_for?(@broker_customer) && (!current_user.has_role? 'sales_rep_for_all_broker_customers')
      unauthorized
    end

    @broker_customer_carriers = BrokerCarrier.where broker: @broker_customer.broker, customer: @broker_customer.customer

    @q = @broker_customer.shipments.ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.blank?
    @pagy, @shipments = pagy(@q.result)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_broker_customer
    @broker_customer = BrokerCustomer.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def broker_customer_params
    params.require(:broker_customer).permit(:id,
                                            :always_show_quotes_based_on_calculated_classes,
                                            :customer_id,
                                            :can_quote,
                                            :default_upcharge,
                                            :default_upcharge_percentage,
                                            :default_bol_notes,
                                            broker_customer_sales_reps_attributes: %i[_destroy id commission_flat commission_percent user_id],
                                            broker_accessorials_attributes: %i[_destroy id accessorial_id flat_charge code name upcharge upcharge_percent],
                                            customer_attributes: %i[_destroy id name],
                                            primary_pickup_address_attributes: %i[id street street2 city state zip_code country_id],
                                            upcharge_rules_attributes: %i[_destroy id max min packaging_id upcharge upcharge_percentage]
                                           )
  end
end
