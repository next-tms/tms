class RefreshOperatorNoticeJob < ApplicationJob
  def perform
    return unless OFREP.configured?

    OperatorNotice.refresh!
  rescue OFREP::Error => e
    Sentry.capture_exception(e)
  end
end
