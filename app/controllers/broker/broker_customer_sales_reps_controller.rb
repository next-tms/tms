# frozen_string_literal: true

class Broker::BrokerCustomerSalesRepsController < Broker::BrokerController
  before_action :set_broker_customer_sales_rep, only: %i[destroy edit show update]
  before_action :authenticate_user!
  before_action :require_admin

  def book
    @user.updated_by = current_user
    @user.save

    @user.booked_at = DateTime.current
    @user.save

    redirect_to [:broker, @user]
  end

  def unbook
    @user.updated_by = current_user
    @user.save

    @user.booked_at = nil
    @user.save

    redirect_to [:broker, @user]
  end

  def index
    @broker_customer_sales_reps = User.where(id: current_user.broker.broker_customer_sales_reps.pluck(:user_id)).order(:first_name)
  end

  def new
    @user = Shipment.new
    @user.items << Item.new

    broker_customer = BrokerCustomer.find_by_id(params[:broker_customer_id])
    @user.shipper_name = broker_customer.customer.name
    @user.broker_customer = broker_customer
    @user.shipper_address = broker_customer.primary_pickup_address.dup
    @user.receiver_address = Address.new
  end

  def new_quote_only
    @user = Shipment.new
    @user.items << Item.new
    @user.shipper_address = Address.new
    @user.receiver_address = Address.new
  end

  def create
    broker_customer = set_user_params[:broker_customer_id].blank? ? nil : BrokerCustomer.find(set_user_params[:broker_customer_id])
    @user = Shipment.new(set_user_params)
    @user.updated_by = current_user
    @user.broker = current_user.broker
    @user.broker_customer = broker_customer
    @user.load_id = current_user.broker.last_load_id + 1
    if @user.save
      if @user.quote_only?
        redirect_to quote_broker_shipment_path(@user)
      else
        redirect_to [:broker, @user]
      end
    else
      render :new
    end
  end

  def edit; end

  def update
    unless current_user.sales_rep_for?(@user.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    @user.updated_by = current_user
    @user.save
    if !@user.update(set_user_params)
      flash[:error] = "Unable to update shipment: #{@user.errors.full_messages.join(', ')}"
      redirect_back fallback_location: edit_broker_shipment_path(@user)
    else
      redirect_to broker_shipment_path(@user)
    end
  end

  def show; end

  def documents; end

  def documents_bol
    unless current_user.sales_rep_for?(@user.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    qrcode = RQRCode::QRCode.new(tracking_url(load_id: @user.load_id))
    @qrcode = qrcode.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 3,
      standalone: true,
      size: 150
    )
    render 'shipments/documents_bol', layout: 'print'
  end

  def documents_quote
    unless current_user.sales_rep_for?(@user.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    render 'shipments/documents_quote', layout: 'print'
  end

  def destroy
    unless current_user.sales_rep_for?(@user.broker_customer) || current_user.has_role?('sales_rep_for_all_broker_customers')
      unauthorized
    end
    if current_user.broker != @user.broker
      flash[:danger] = '403 Unauthorized'
    else
      @user.destroy
      flash[:notice] = 'Shipment deleted'
    end
    redirect_to shipments_path
  end

  def missing_delivery_appointment
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).missing_delivery_appointment)
  end

  def missing_pricing
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.missing_pricing.order(:created_at))
  end

  def missing_pro
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.missing_pro.order(:created_at))
  end

  def booked
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.booked.order(:booked_at))
  end

  def pending_dispatch
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_dispatch.order(:created_at))
  end

  def pending_delivery
    shipments = Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_delivery
    @late_shipments = shipments.late.order(:picked_up_at)
    @users = shipments.not_late.order(:picked_up_at)
  end

  def pending_departure
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_departure.order(:picked_up_at))
  end

  def pending_found
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).pending_found.order(:created_at))
  end

  def pending_pickup
    pending_pickup = Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_pickup.or(Shipment.where(broker_customer: [current_user.broker_customers]).canceled_recently.pending_pickup).distinct

    @users_for_pickup_later = Shipment.none
    @users_for_pickup_today = Shipment.none
    @users_missed_pickup = Shipment.none

    pending_pickup.each do |shipment|
      if shipment.late?
        @users_missed_pickup += [shipment]
        next
      end

      if shipment.pickup_by.blank?
        @users_for_pickup_today += [shipment]
        next
      end

      if shipment.pickup_by >= shipment.shipper_address.time_zone.local_to_utc(Date.current.next_day.beginning_of_day)
        @users_for_pickup_later += [shipment]
      else
        @users_for_pickup_today += [shipment]
      end
    end

    # @users_for_pickup_today = pending_pickup.where(pickup_on: nil).or(pending_pickup.where('pickup_on <= ?', Date.current)).distinct.order(:pickup_hours_end_at)
    # @users_for_pickup_later = pending_pickup.where('pickup_on > ?', Date.current).order(:pickup_hours_end_at)
  end

  def pending_quotation
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.pending_quotation.or(Shipment.where(broker_customer: [current_user.broker_customers]).canceled_recently).distinct.order(:created_at))
  end

  def delivered
    @pagy, @users = pagy(Shipment.where(broker_customer: [current_user.broker_customers]).active.delivered.order(delivered_at: :desc))
  end

  def notes; end

  def pickup; end

  def pricing
    unauthorized if (!current_user.has_role? 'accounting') && !current_user.sales_rep_for?(@user.broker_customer)
  end

  def create_tracking_event
    @tracking_event = TrackingEvent.new(tracking_event_params)
    @tracking_event.shipment = @user
    if @tracking_event.save
      redirect_to tracking_events_broker_shipment_path(@user)
    else
      render :edit_tracking_events
    end
  end

  def edit_tracking_events
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@user.broker_customer)
  end

  def tracking_events
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@user.broker_customer)
  end

  def transit
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@user.broker_customer)
  end

  def transit_edit
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@user.broker_customer)
  end

  def delivery; end

  def quote
    unauthorized if (!current_user.has_role? 'dispatch') && !current_user.sales_rep_for?(@user.broker_customer)
    @user.update_rates
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def require_admin
    require_role 'admin'
  end

  def set_broker_customer_sales_rep
    @broker_customer_sales_rep = current_user.broker.users.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def set_user_params
    params.require(:user).permit(:id)
  end
end
