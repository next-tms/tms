class FreightKitSnitchService
  def self.snitch(error:, record:, request:, response:)
    return if error.is_a?(FreightKit::Error) && Rails.env.production?

    message = "#{record.class.name} id=#{record&.id || '(new)'}\n" \
              "error   : #{error.inspect}\n" \
              "request : #{request}\n" \
              "response: #{response}"

    return Sentry.capture_exception(error, extra: { error_message: message }) if Rails.env.production?

    Rails.logger.debug(message)
  end
end
