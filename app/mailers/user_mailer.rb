class UserMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'
  helper :application, :date_time

  before_action :set_actor, except: :send_welcome
  before_action :set_shipment, except: %i[send_welcome pickup_service_dispatched]

  def send_welcome(user)
    @user = user
    @name = Setting.value!(:name)
    mail(
      from: "#{@name} <#{Setting.robot_email!}>",
      reply_to: "#{@name} <#{Setting.customer_service_email!}>",
      to: @user.email,
      subject: "Welcome to #{@name}"
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

  def pickup_service_dispatched
    @pickup = params[:pickup]
    return if @pickup.shipment.updated_by.present? || @pickup.shipment.pickup_confirmation.blank?

    @subject = "#{@pickup.dispatcher.first_name} #{@pickup.dispatcher.last_name} Dispatched Load #{@pickup.shipment.load_id}"

    send_shipment_updated(@pickup.shipment, __method__)
  end

  def dispatcher_id
    @subject = "Assigned #{@shipment.load_id} to you"
    send_shipment_updated(@shipment, __method__)
  end

  private

  def send_shipment_updated(shipment, method_name)
    recipient = params[:recipient] ? "#{params[:recipient].full_name} <#{params[:recipient].email}>" : to(shipment, method_name)

    mail(from: from(shipment), reply_to:, to: recipient, subject: [who_performed, @subject].join(' '))
  end

  def set_actor = @actor = params[:actor]

  def set_shipment
    @shipment = params[:shipment]
  end

  def from(_shipment)
    "#{Setting.value!(:name)} <#{Setting.robot_email!}>"
  end

  def to(shipment, method)
    user_ids = ((shipment.broker_customer&.sales_reps&.ids || []) + User.broker.with_role('dispatch')&.ids) || []
    user_ids -= User.broker.with_role('notifications:-dispatch').ids unless method == :new_shipment

    users = User.distinct.active.where(id: user_ids)

    users.inject('') do |str, user|
      user.receive_email_notifications? ? "#{str}#{user.first_name} #{user.last_name} <#{user.email}>, " : str
    end[0..-3]
  end

  def reply_to = @actor.blank? ? "Robot <#{Setting.robot_email!}>" : "#{@actor.full_name} <#{@actor.email}>"
  def who_performed = @actor&.full_name || 'Robot'
end
