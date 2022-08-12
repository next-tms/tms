class ApplicationMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>'
  layout 'mailer'

  rescue_from Postmark::InactiveRecipientError, with: :notify_honeybadger
  # https://github.com/ActiveCampaign/postmark-rails/wiki/Error-Handling#actionmailer-5

  def notify_honeybadger(error)
    # Notify once, But prevent ActionMailer from retrying te job
    Honeybadger.notify(error)
  end
end
