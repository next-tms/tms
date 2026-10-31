module HasAPI
  extend ActiveSupport::Concern

  included do
    scope :errored, -> { where.not(api_errors: '[]') }
    scope :successful, -> { where(api_errors: '[]') }
  end

  def api_errors=(object)
    super(sanitize_api_object(object))
  end

  def api_errors
    return super unless super.is_a?(String)

    JSON.parse(super)
  end

  def api_request=(object)
    super(sanitize_api_object(object))
  end

  def api_response=(object)
    super(sanitize_api_object(object))
  end

  def human_readable_errors
    HasAPI::ErrorParser.call(self)
  end

  def errored?
    api_errors.any?
  end

  def api_backed? = true

  def successful?
    !errored?
  end

  private

  def sanitize_api_object(object)
    case object
    when Array, Hash then return object.to_json
    when NilClass then return object
    when String
      return sanitize_api_object({ url: object }) if object.start_with?('http://') || object.start_with?('https://')

      begin
        return sanitize_api_object(JSON.parse(object))
      rescue JSON::ParserError
        # do nothing
      end

    end

    raise "Not sure how to convert #{object.class} to JSON: #{object}"
  end
end
