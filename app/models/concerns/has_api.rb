# frozen_string_literal: true

module HasAPI
  extend ActiveSupport::Concern

  included do
    scope :errored, -> { where.not(api_errors: '[]').or(where.not(error_object: nil).where.not(error_object: '')) }
    scope :successful, -> { where(api_errors: '[]').where(error_object: [nil, '']) }
  end

  def api_errors=(object)
    super(sanitize_api_object(object))
  end

  def api_errors
    return super unless super.is_a?(String)

    JSON.parse(super, symbolize_names: true)
  end

  def api_request=(object)
    super(sanitize_api_object(object))
  end

  def api_response=(object)
    super(sanitize_api_object(object))
  end

  def errored?
    api_errors.any? || error_object.present?
  end

  def successful?
    !errored?
  end

  private

  def sanitize_api_object(object)
    case object
    when Array then object.to_json
    when Hash then return object.to_json
    when String
      begin
        return sanitize_api_object(JSON.parse(object))
      rescue JSON::ParserError
        # do nothing
      end
    end

    object
  end
end
