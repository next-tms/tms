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

  def initialize(shipment:)
    @shipment = shipment
    @broker_carrier = shipment.broker_carrier
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
    args = TransponderGraphqlInputBuilder.new(shipment:, opts: opts, operation: operation_class.underscore).call

    GraphqlClient::Transponder::Client.query(
      "#{operation}::#{operation_class}::DETAILS".constantize, variables: {
        **args,
      }.compact
    )
  rescue *API_EXCEPTIONS => e
    raise TransponderApiError, e.message
  end

  def parse_response(response:, operation_name:)
    return response.errors.messages if response.errors.present?

    response.original_hash.dig('data', operation_name).deep_symbolize_keys
  end
end
