# To deliver this notification:
#
# ShipmentNotification.with(post: @post).deliver_later(current_user)
# ShipmentNotification.with(post: @post).deliver(current_user)

class ShipmentNotification < NotificationBase
  param :shipment, :attribute_changed

  def mailer_class
    UserMailer
  end

  def mailer_params
    { shipment: params[:shipment] }
  end

  def mailer_method
    params[:attribute_changed]
  end

  def message
    shipment = params[:shipment].reload
    attribute_changed = params[:attribute_changed].to_sym
    updated_by = shipment.updated_by&.full_name || 'Robot'

    return "#{updated_by} Cancelled Load ##{shipment.load_id}" if attribute_changed == :canceled_at
    return "#{updated_by} Entered Load ##{shipment.load_id}" if attribute_changed == :new_shipment
    return "#{updated_by} Updated Load ##{shipment.load_id} ETA" if attribute_changed == :delivery_eta_on

    "#{updated_by} Marked Load ##{shipment.load_id} #{humanized_attribute_changed}"
  end

  def humanized_attribute_changed
    return params[:shipment].booked_at.blank? ? 'Unbooked' : 'Booked' if params[:attribute_changed].to_sym == :booked_at

    case params[:attribute_changed].to_sym
    when :delivered_at then 'Delivered'
    when :delivery_appointment_at then 'Scheduled for Delivery'
    when :delivery_appointment_on then 'Scheduled for Delivery'
    when :departed_origin_terminal_at then 'Departed from Origin Terminal"'
    when :out_for_delivery_at then 'Out for Delivery'
    when :picked_up_at then 'Picked Up'
    end
  end

  def notification_subject
    message
  end
end
