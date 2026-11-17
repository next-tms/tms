MCP.configure do |config|
  config.exception_reporter = ->(exception, server_context) { Rails.error.report(exception, context: server_context) }
end
