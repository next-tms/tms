class NotificationBase < Noticed::Base
  deliver_by :database
  deliver_by :email,
              mailer: :mailer_class,
              method: :mailer_method,
              format: :mailer_params,
              delay: 2.minutes,
              if: :unread?
              # Deliver Email Notification if after 2 minutes the user hasn't viewed
              # the notification in the dashboard

  include ActionView::Helpers::UrlHelper # For link_to

  def raw_content
    shipment = params[:shipment] || mapped_shipment
    host = shipment.broker_customer.broker.websites.first.domain
    host = 'localhost:3000' if Rails.env.development?

    "
    <p><b> #{notification_subject} </b></p>

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