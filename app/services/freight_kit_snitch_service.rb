# frozen_string_literal: true

class FreightKitSnitchService
  def self.snitch(error:, record:, request:, response:)
    return false if error.is_a?(FreightKit::Error) && Rails.env.production?

    message = "#{record.class.name} id=#{record&.id || "(new)"}\n"\
              "error   : #{error.inspect}\n"\
              "request : #{request}\n"\
              "response: #{response}"

    if Rails.env.production?
      Honeybadger.notify(error:, error_message: message)

      return true
    end

    Rails.logger.debug(message)

    true
  end
end
