# To deliver this notification:
#
# PickupNotifier.with(post: @post).deliver(current_user)

class PickupNotifier < BaseNotifier
  required_params :pickup, :pickup_action_type

  def mailer_class(_notification = nil) = UserMailer
  def mailer_params(_notification = nil) = { pickup: params[:pickup] }
  def mailer_method(_notification = nil) = params[:pickup_action_type]
  def mapped_shipment = params[:pickup].shipment
  def notification_type = "pickup:#{params[:pickup_action_type]}"

  def message
    pickup = params[:pickup]

    "#{pickup.dispatcher.first_name} #{pickup.dispatcher.last_name} Dispatched Load #{pickup.shipment.load_id}"
  end

  def notification_subject = message
  def url = transit_broker_shipment_path(params[:pickup].shipment, attr: :dispatched_at)
end
