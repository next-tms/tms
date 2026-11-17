class GraphQLController < ActionController::API
  include APIRateLimiting
  include GraphQLAuthentication
  include Localization

  INTROSPECTION_LIMITS = { max_complexity: 400, max_depth: 15 }.freeze

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = { authorizable:, session: }
    limits = introspection?(query, operation_name:) ? INTROSPECTION_LIMITS : {}
    @result = LiftoffSchema.execute(query, variables:, context:, operation_name:, **limits)
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  def handle_error_in_development(error)
    logger.error(error.message)
    logger.error(error.backtrace.join("\n"))

    render(:error, locals: { error: }, status: :internal_server_error)
  end

  def introspection?(query, operation_name:)
    operation = GraphQL::Query.new(LiftoffSchema, query, operation_name:).selected_operation

    operation.present? && operation.selections.all? do |selection|
      selection.is_a?(GraphQL::Language::Nodes::Field) && selection.name.start_with?('__')
    end
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end
end
