# To deliver this notification:
#
# PickupNotification.with(post: @post).deliver_later(current_user)
# PickupNotification.with(post: @post).deliver(current_user)

class PickupNotification < NotificationBase
  param :pickup, :pickup_action_type

  def mailer_class
    UserMailer
  end

  def mailer_params
    { pickup: params[:pickup] }
  end

  def mailer_method
    params[:pickup_action_type]
  end

  def mapped_shipment
    params[:pickup].shipment
  end

  def url
    transit_broker_shipment_path(params[:pickup].shipment, attr: :dispatched_at)
  end

  def notification_type
    "pickup:#{params[:pickup_action_type]}"
  end

  def message
    pickup = params[:pickup]

    "#{pickup.dispatcher.first_name} #{pickup.dispatcher.last_name} Dispatched Load #{pickup.shipment.load_id}"
  end

  def notification_subject
    message
  end
end
