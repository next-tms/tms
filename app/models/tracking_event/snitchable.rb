# frozen_string_literal: true

module TrackingEvent::Snitchable
  extend ActiveSupport::Concern

  included do
    before_validation :snitch

    def snitch
      messages = []

      unless at.blank?
        messages << "has an #at in the future: #{at}" if at > 1.year.from_now
        messages << "has an #at in the past: #{at}" if at < 1.year.ago
      end

      unless city.blank?
        messages << "has a numeric #city: #{city}" if city.to_i.to_s == city
        messages << "has a short #city: #{city}" if city.size < 5
      end

      return unless messages.any?

      SnitchService.snitch(self, messages)
    end
  end
end
