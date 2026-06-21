# To deliver this notification:
#
# DocumentNotifier.with(post: @post).deliver(current_user)

class DocumentNotifier < BaseNotifier
  required_params :shipment, :document_type, :contact

  def mailer_class(_notification = nil) = ContactMailer

  def mailer_params(_notification = nil)
    {
      from_user: params[:from_user],
      to_contact: params[:contact],
      shipment: params[:shipment],
      document_type: params[:document_type]
    }
  end

  def notification_type = "document:#{params[:document_type]}"
  def mailer_method(_notification = nil) = :from_notification
  def message = "#{humanized_document_type} for Load ##{params[:shipment].load_id} is available"

  def humanized_document_type
    case params[:document_type].to_sym
    when :carrier_bol then 'Scanned Bill of Landing'
    when :carrier_pod then 'Proof of Delivery'
    when :broker_quote then 'Quote'
    when :broker_dispatch_sheet then 'Dispatch Sheet'
    when :broker_bol then 'Bill of Landing'
    end
  end

  def notification_subject = "Your #{humanized_document_type} is attached for the following shipment (Load ##{params[:shipment].load_id})"
  def url = documents_broker_shipment_path(params[:shipment], attr: params[:document_type])
end
