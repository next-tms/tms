class UserMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'

  def send_welcome(user)
    @user = user
    @broker = @user.customer? ? @user.broker_customer.broker : @user.broker
    mail(
      from: "#{@broker.name} <#{@broker.customer_service_email}>",
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

  private

  def from(shipment)
    "#{shipment.broker.name} <robot@#{shipment.broker.customer_service_email.split('@')[1]}>"
  end

  def to(shipment, method)
    users = shipment.broker_customer.sales_reps + shipment.broker.users.with_role('dispatch')
    users.uniq!
    users -= shipment.broker.users.with_role('notifications:-dispatch') unless [:new_shipment].include?(method)

    users.inject('') { |str, user| str = user.receive_email_notifications? ? str + "#{user.first_name} #{user.last_name} <#{user.email}>, " : str + '' }[0..-3]
  end

  def reply_to(shipment, __method__)
    return "Robot <robot@#{shipment.broker.customer_service_email.split('@')[1]}>" if shipment.updated_by.blank?

    "#{shipment.updated_by.first_name} #{shipment.updated_by.last_name} <#{shipment.updated_by.email}>"
  end

  def who_performed(shipment)
    return 'Robot' if shipment.updated_by.blank?

    "#{shipment.updated_by.first_name} #{shipment.updated_by.last_name}"
  end
end
