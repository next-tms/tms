class MCPController < ActionController::API
  include APIRateLimiting
  include GraphQLAuthentication

  class << self
    def server_name = Setting.value!(:name).parameterize
  end

  TOOLS = [
    Tools::CreateQuote,
    Tools::CreateShipment,
    Tools::FetchRates,
    Tools::GetBill,
    Tools::GetCarrier,
    Tools::GetCustomer,
    Tools::GetInvoice,
    Tools::GetShipment,
    Tools::GraphQLQuery,
    Tools::GraphQLSchema,
    Tools::SearchBills,
    Tools::SearchCarriers,
    Tools::SearchCustomers,
    Tools::SearchInvoices,
    Tools::SearchShipments
  ].freeze

  def create
    body = server.handle_json(request.raw_post)

    if body.nil?
      head(:accepted)
      return
    end

    render(body:, content_type: Mime[:json])
  end

  private

  def instructions
    <<~TEXT.squish
      Tools for the TMS (transportation management system) of #{Setting.value!(:name)} at #{request.host}.
      Use them for questions about #{Setting.value!(:name)} shipments, quotes, invoices, bills, customers, and carriers.
      A load number is the load ID of a shipment: get_shipment returns its dates, ETA, promised delivery, and tracking events.
      Each tool runs as the user who owns the API key, so results only include the records and fields that user can see.
    TEXT
  end

  def server
    MCP::Server.new(
      instructions:,
      name: self.class.server_name,
      server_context: { authorizable:, session: },
      title: "#{Setting.value!(:name)} TMS",
      tools: TOOLS
    )
  end
end
