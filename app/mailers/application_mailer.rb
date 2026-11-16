class ApplicationMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>'
  layout 'mailer'

  rescue_from Postmark::InactiveRecipientError, with: :notify_sentry_and_store_error_msg
  # https://github.com/ActiveCampaign/postmark-rails/wiki/Error-Handling#actionmailer-5

  def notify_sentry_and_store_error_msg(error)
    # Notify once, But prevent ActionMailer from retrying te job
    Sentry.capture_exception(error)
    event = params[:notification]&.event
    return if event.blank?

    event.params[:email_delivery_error] = "#{error.class} | #{error}"
    event.save
  end
end
