class NotifyExpiringAPIKeysJob < ApplicationJob
  NOTICES = [1.day, APIKey::EXPIRES_SOON].freeze

  def perform
    NOTICES.each do |notice|
      APIKey
        .active
        .where
        .missing(:rolled_to)
        .where(expires_at: notice.from_now...(notice + 1.day).from_now)
        .find_each { |api_key| APIKeyMailer.with(api_key:).expiring.deliver_later }
    end
  end
end
