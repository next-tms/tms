# To deliver this notification:
#
# DocumentNotification.with(post: @post).deliver_later(current_user)
# DocumentNotification.with(post: @post).deliver(current_user)

class DocumentNotification < NotificationBase
  param :shipment, :document_type, :contact

  def mailer_class
    ContactMailer
  end

  def mailer_params
    {
      from_user: params[:from_user],
      to_contact: params[:contact],
      shipment: params[:shipment],
      document_type: params[:document_type]
    }
  end

  def notification_type
    "document:#{params[:document_type]}"
  end

  def mailer_method
    :from_notification
  end

  def message
    "#{humanized_document_type} for Load ##{params[:shipment].load_id} is available"
  end

  def humanized_document_type
    case params[:document_type].to_sym
    when :carrier_bol then 'Scanned Bill of Landing'
    when :carrier_pod then 'Proof of Delivery'
    when :broker_quote then 'Quote'
    when :broker_dispatch_sheet then 'Dispatch Sheet'
    when :broker_bol then 'Bill of Landing'
    end
  end

  def notification_subject
    "Your #{humanized_document_type} is attached for the following shipment (Load ##{params[:shipment].load_id})"
  end
end
