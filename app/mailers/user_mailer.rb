class UserMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'
  helper :application

  before_action :set_shipment, except: %i[send_welcome pickup_service_dispatched]

  def send_welcome(user)
    @user = user
    @broker = @user.customer? ? @user.broker_customer.broker : @user.broker
    mail(
      from: "#{@broker.name} <#{@broker.robot_email}>",
      reply_to: "#{@broker.name} <#{@broker.customer_service_email}>",
      to: @user.email,
      subject: "Welcome to #{@broker.name}"
    )
  end

  def new_shipment
    @subject = "Entered Load #{@shipment.load_id}"
    send_shipment_updated(@shipment, __method__)
  end

  def booked_at
    @subject = "Marked Load #{@shipment.load_id} #{@shipment.booked_at.blank? ? 'Unbooked' : 'Booked'}"
    send_shipment_updated(@shipment, __method__)
  end

  def canceled_at
    @subject = "Canceled Load #{@shipment.load_id}"
    send_shipment_updated(@shipment, __method__)
  end

  def delivered_at
    @subject = "Marked Load #{@shipment.load_id} Delivered"
    send_shipment_updated(@shipment, __method__)
  end

  def delivery_appointment_at
    @subject = "Marked Load #{@shipment.load_id} Scheduled for Delivery"
    send_shipment_updated(@shipment, __method__)
  end

  def delivery_appointment_on
    @subject = "Marked Load #{@shipment.load_id} Scheduled for Delivery"
    send_shipment_updated(@shipment, __method__)
  end

  def delivery_eta_on
    @subject = "Updated Load #{@shipment.load_id} ETA"
    send_shipment_updated(@shipment, __method__)
  end

  def departed_origin_terminal_at
    @subject = "Marked Load #{@shipment.load_id} Departed from Origin Terminal"
    send_shipment_updated(@shipment, __method__)
  end

  def out_for_delivery_at
    @subject = "Marked Load #{@shipment.load_id} Out for Delivery"
    send_shipment_updated(@shipment, __method__)
  end

  def picked_up_at
    @subject = "Marked Load #{@shipment.load_id} Picked Up"
    send_shipment_updated(@shipment, __method__)
  end

  def pickup_service_dispatched(pickup)
    @pickup = pickup
    return if !@pickup.shipment.updated_by.blank? || @pickup.shipment.pickup_confirmation.blank?

    mail(
      from: from(@pickup.shipment),
      reply_to: reply_to(@pickup.shipment, __method__),
      to: to(pickup.shipment, __method__),
      subject: "#{@pickup.dispatcher.first_name} #{@pickup.dispatcher.last_name} Dispatched Load #{@pickup.shipment.load_id}"
    )
  end

  private

  def send_shipment_updated(shipment, method_name)
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment),
      to: to(shipment, method_name),
      subject: [who_performed(@shipment), @subject].join(' ')
    )
  end

  def set_shipment
    @shipment = params[:shipment]
  end

  def from(shipment)
    "#{shipment.broker.name} <#{shipment.broker.robot_email}>"
  end

  def to(shipment, method)
    user_ids = (shipment.broker_customer&.sales_reps&.ids || []) + shipment.broker.users.with_role('dispatch')&.ids || []
    user_ids -= shipment.broker.users.with_role('notifications:-dispatch').ids unless method == :new_shipment

    users = User.distinct.active.where(id: user_ids)

    users.inject('') do |str, user|
      str = user.receive_email_notifications? ? str + "#{user.first_name} #{user.last_name} <#{user.email}>, " : str + ''
    end    [0..-3]
  end

  def reply_to(shipment)
    return "Robot <#{shipment.broker.robot_email}>" if shipment.updated_by.blank?

    "#{shipment.updated_by.first_name} #{shipment.updated_by.last_name} <#{shipment.updated_by.email}>"
  end

  def who_performed(shipment)
    return 'Robot' if shipment.updated_by.blank?

    "#{shipment.updated_by.first_name} #{shipment.updated_by.last_name}"
  end
end
