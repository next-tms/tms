# frozen_string_literal: true

class TransponderService
  attr_reader :shipment, :broker_carrier

  QUERY = GraphqlClient::Queries
  MUTATION = GraphqlClient::Mutations

  API_EXCEPTIONS = [
    EOFError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Net::OpenTimeout,
    Net::ReadTimeout,
    OpenSSL::SSL::SSLError,
    RuntimeError
  ].freeze

  class TransponderApiError < StandardError; end

  def initialize(shipment:, broker_carrier: nil)
    @shipment = shipment
    @broker_carrier = broker_carrier.presence || shipment.broker_carrier
  end

  def tracking
    response = commit(operation_class: 'Tracking')
    parse_response(response:, operation_name: 'trackingInfo')
  end

  def document(document_type:)
    response = commit(opts: { document_type: document_type.upcase }, operation_class: 'Document')
    parsed_response = parse_response(response:, operation_name: 'document')
    return parsed_response unless parsed_response[:data]

    # GraphQL doesn't allow non UTF-8 Strings to be passed in the response, To resolve, Data from Transponder will be
    # Base64 encoded and will be decoded afterwards
    parsed_response[:data] = Base64.decode64 parsed_response[:data]
    parsed_response
  end

  def fetch_pro
    response = commit(operation_class: 'FetchPro')
    parse_response(response:, operation_name: 'fetchPro')
  end

  def rates(use_forced_freight_classes:)
    response = commit(opts: { use_forced_freight_classes: }, operation_class: 'Rates')
    parse_response(response:, operation_name: 'fetchRates')
  end

  def create_pickup(pickup:)
    response = commit(
      opts: { use_forced_freight_classes: !pickup.rate.with_calculated_freight_classes, pickup: },
      operation_class: 'CreatePickup',
      operation: MUTATION
    )
    parse_response(response:, operation_name: 'createPickup')
  end

  private

  def commit(opts: {}, operation_class:, operation: QUERY)
    return if broker_carrier.to_freight_kit_carrier.blank?

    args = TransponderGraphqlInputBuilder.new(
      shipment:,
      opts: opts,
      operation: operation_class.underscore,
      broker_carrier: broker_carrier
    ).call

    response = GraphqlClient::Transponder::Client.query(
      "#{operation}::#{operation_class}::DETAILS".constantize, variables: {
        **args,
      }.compact
    )

    return response unless response.original_hash['errors'].present?

    error_msgs = response.original_hash['errors'].map { |k| k['message'] }.join(', ')
    raise TransponderApiError, error_msgs
  rescue *API_EXCEPTIONS => e
    raise TransponderApiError, e.message
  end

  def parse_response(response:, operation_name:)
    return if response.blank?
    return response.errors.messages if response.errors.present?

    data_obj = response.original_hash.dig('data', operation_name)
    return data_obj if data_obj.blank?
    return data_obj if data_obj.is_a?(String)

    data_obj.deep_symbolize_keys
  end
end
