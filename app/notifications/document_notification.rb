# To deliver this notification:
#
# DocumentNotification.with(post: @post).deliver_later(current_user)
# DocumentNotification.with(post: @post).deliver(current_user)

class DocumentNotification < Noticed::Base
  include ActionView::Helpers::UrlHelper # For link_to

  deliver_by :database
  deliver_by :email,
              mailer: "ContactMailer",
              method: :mailer_method,
              format: :mailer_params,
              delay: 1.minute,
              if: :unread?
              # Deliver Email Notification if after 10 minutes the user hasn't viewed
              # the notification in the dashboard

  param :shipment, :document_type, :contact

  def mailer_params
    {
      from_user: params[:from_user],
      to_contact: params[:contact],
      shipment: params[:shipment],
      document_type: params[:document_type]
    }
  end

  def mailer_method
    :from_notification
  end

  def message
    "#{humanized_document_type} for Load ##{params[:shipment].load_id} is available"
  end

  def humanized_document_type
    case params[:document_type]
    when :carrier_bol then 'Scanned Bill of Landing'
    when :carrier_pod then 'Proof of Delivery'
    when :broker_quote then 'Quote'
    when :broker_dispatch_sheet then 'Dispatch Sheet'
    when :broker_bol then 'Bill of Landing'
    end
  end

  def raw_content
    shipment = params[:shipment]
    host = shipment.broker_customer.broker.websites.first.domain
    host = 'localhost:3000' if Rails.env.development?

    "
    <p>Your #{humanized_document_type} is attached for the following shipment (Load ##{shipment.load_id}):</p>

    <p>From:</p>
    <address>
      #{shipment.shipper_name}
      <br>
      #{shipment.shipper_address.pretty('<br>').html_safe}
    </address>

    <p>To:</p>
    <address>
      #{shipment.receiver_name}
      <br>
      #{shipment.receiver_address.pretty('<br>').html_safe}
    </address>

    #{link_to "View shipment", broker_shipment_url(shipment, host: host)}
    "
  end
end
