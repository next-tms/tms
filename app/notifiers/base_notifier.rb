# frozen_string_literal: true

class BaseNotifier < Noticed::Event
  deliver_by :email,
             mailer: :mailer_class,
             method: :mailer_method,
             format: :mailer_params,
             delay: 2.minutes,
             if: :should_receive_email_notification?

  include ActionView::Helpers::UrlHelper # For link_to

  def failed_email_delivery?
    params[:email_delivery_error].present?
  end

  def should_receive_email_notification?
    blacklist = recipient.email_notifications_blacklist || []

    recipient.receive_email_notifications? &&
      (recipient.receive_read_notifications_by_email? || unread?) &&
      blacklist.exclude?(notification_type)
  end

  def raw_content
    shipment = params[:shipment] || mapped_shipment

    <<~HTML
      <p><b> #{notification_subject} </b></p>

      <p>From:</p>
      <address>
        #{shipment.shipper_name}
        <br>
        #{shipment.shipper_address.pretty("<br>").html_safe}
      </address>

      <p>To:</p>
      <address>
        #{shipment.receiver_name}
        <br>
        #{shipment.receiver_address.pretty("<br>").html_safe}
      </address>

      #{link_to("View shipment", url)}
    HTML
  end
end
