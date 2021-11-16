class UserMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'
  helper :application

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

  def new_shipment(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Entered Load #{shipment.load_id}"
    )
  end

  def booked_at(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} #{shipment.booked_at.blank? ? 'Unbooked' : 'Booked'}"
    )
  end

  def delivered_at(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} Delivered"
    )
  end

  def delivery_appointment_at(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} Scheduled for Delivery"
    )
  end

  def delivery_appointment_on(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} Scheduled for Delivery"
    )
  end

  def departed_origin_terminal_at(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} Departed from Origin Terminal"
    )
  end

  def out_for_delivery_at(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} Out for Delivery"
    )
  end

  def picked_up_at(shipment)
    @shipment = shipment
    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Marked Load #{shipment.load_id} Picked Up"
    )
  end

  def pickup_service_dispatched(shipment)
    @shipment = shipment
    return if @shipment.pickup.blank? || !@shipment.updated_by.blank? || @shipment.pickup_confirmation.blank?

    mail(
      from: from(shipment),
      reply_to: reply_to(shipment, __method__),
      to: to(shipment, __method__),
      subject: "#{who_performed(shipment)} Dispatched Load #{shipment.load_id}"
    )
  end

  private

  def from(shipment)
    "#{shipment.broker.name} <#{@shipment.broker.robot_email}>"
  end

  def to(shipment, method)
    users = (shipment.broker_customer&.sales_reps || []) + shipment.broker.users.with_role('dispatch')
    users.uniq!
    users -= shipment.broker.users.with_role('notifications:-dispatch') unless [:new_shipment].include?(method)

    users.inject('') do |str, user|
      str = user.receive_email_notifications? ? str + "#{user.first_name} #{user.last_name} <#{user.email}>, " : str + ''
    end    [0..-3]
  end

  def reply_to(shipment, __method__)
    return "Robot <#{shipment.broker.robot_email}>" if shipment.updated_by.blank?

    "#{shipment.updated_by.first_name} #{shipment.updated_by.last_name} <#{shipment.updated_by.email}>"
  end

  def who_performed(shipment)
    return 'Robot' if shipment.updated_by.blank?

    "#{shipment.updated_by.first_name} #{shipment.updated_by.last_name}"
  end
end
