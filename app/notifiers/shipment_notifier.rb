# To deliver this notification:
#
# ShipmentNotifier.with(post: @post).deliver(current_user)

class ShipmentNotifier < BaseNotifier
  required_params :shipment, :attribute_changed

  def mailer_class
    UserMailer
  end

  def mailer_params
    { shipment: params[:shipment] }
  end

  def mailer_method
    params[:attribute_changed]
  end

  def notification_type
    "shipment:#{params[:attribute_changed]}"
  end

  def url
    return broker_shipment_path(params[:shipment]) if %i[
                                                        canceled_at
                                                         new_shipment
                                                      ].include?(params[:attribute_changed].to_sym)

    return broker_shipment_path(
      params[:shipment],
                                attr: params[:attribute_changed],
    ) if %i[dispatcher_id].include?(params[:attribute_changed].to_sym)

    transit_broker_shipment_path(params[:shipment], attr: params[:attribute_changed])
  end

  def message
    shipment = params[:shipment].reload
    attribute_changed = params[:attribute_changed].to_sym
    updated_by = shipment.updated_by&.full_name || 'Robot'

    return "#{updated_by} Cancelled Load ##{shipment.load_id}" if attribute_changed == :canceled_at
    return "#{updated_by} Entered Load ##{shipment.load_id}" if attribute_changed == :new_shipment
    return "#{updated_by} Updated Load ##{shipment.load_id} ETA" if attribute_changed == :delivery_eta_on
    return "#{updated_by} assigned ##{shipment.load_id} to you" if attribute_changed == :dispatcher_id

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
