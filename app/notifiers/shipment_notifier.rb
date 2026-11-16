# To deliver this notification:
#
# ShipmentNotifier.with(post: @post).deliver(current_user)

class ShipmentNotifier < BaseNotifier
  required_params :shipment, :attribute_changed

  HUMANIZED_ATTRIBUTES = {
    delivered_at: 'Delivered',
    delivery_appointment_at: 'Scheduled for Delivery',
    delivery_appointment_on: 'Scheduled for Delivery',
    departed_origin_terminal_at: 'Departed from Origin Terminal"',
    out_for_delivery_at: 'Out for Delivery',
    picked_up_at: 'Picked Up'
  }.freeze

  def mailer_class(_notification = nil) = UserMailer
  def mailer_params(_notification = nil) = { actor: params[:actor], shipment: params[:shipment] }
  def mailer_method(_notification = nil) = params[:attribute_changed]
  def notification_type = "shipment:#{params[:attribute_changed]}"

  def message
    shipment = params[:shipment]
    attribute_changed = params[:attribute_changed].to_sym
    updated_by = params[:actor]&.full_name || 'Robot'

    return "#{updated_by} Cancelled Load ##{shipment.load_id}" if attribute_changed == :canceled_at
    return "#{updated_by} Entered Load ##{shipment.load_id}" if attribute_changed == :new_shipment
    return "#{updated_by} Updated Load ##{shipment.load_id} ETA" if attribute_changed == :delivery_eta_on
    return "#{updated_by} assigned ##{shipment.load_id} to you" if attribute_changed == :dispatcher_id

    "#{updated_by} Marked Load ##{shipment.load_id} #{humanized_attribute_changed}"
  end

  def humanized_attribute_changed
    return params[:shipment].booked_at.blank? ? 'Unbooked' : 'Booked' if params[:attribute_changed].to_sym == :booked_at

    HUMANIZED_ATTRIBUTES[params[:attribute_changed].to_sym]
  end

  def notification_subject = message

  def url
    return broker_shipment_path(params[:shipment]) if %i[canceled_at new_shipment].include?(params[:attribute_changed].to_sym)

    if %i[dispatcher_id].include?(params[:attribute_changed].to_sym)
      return broker_shipment_path(params[:shipment], attr: params[:attribute_changed])
    end

    transit_broker_shipment_path(params[:shipment], attr: params[:attribute_changed])
  end
end
