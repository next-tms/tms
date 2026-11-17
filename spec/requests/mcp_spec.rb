require 'rails_helper'

RSpec.describe('MCP') do
  describe 'GET /mcp' do
    before { get('/mcp') }

    it { is_expected.to(have_http_status(:method_not_allowed)) }
    it { expect(response.headers['Allow']).to(eq('POST')) }
  end

  describe 'POST /mcp' do
    let(:api_key) { create(:api_key) }
    let(:body) { { id: 1, jsonrpc: '2.0', method: rpc_method, params: }.to_json }
    let(:cache_store) { MCPController.cache_store }
    let(:headers) { { 'Authorization' => "Bearer #{api_key.token}", 'Content-Type' => 'application/json' } }
    let(:json) { response.parsed_body }
    let(:params) { {} }
    let(:request_count) { 1 }
    let(:rpc_method) { 'tools/list' }

    before do
      seed_settings
      allow(cache_store).to(receive(:increment).and_return(request_count))
      post('/mcp', headers:, params: body)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.media_type).to(eq('application/json')) }
    it { expect(json.dig('result', 'tools').pluck('name')).to(eq(MCPController::TOOLS.map(&:name_value))) }
    it { expect(json.dig('result', 'tools').pluck('description')).to(eq(MCPController::TOOLS.map(&:description_value))) }
    it { expect(api_key.reload.last_used_at).to(be_present) }
    it { expect(cache_store).to(have_received(:increment).with(a_string_ending_with(":api_key:#{api_key.token_digest}"), 1, any_args)) }

    context 'when the API key is over the rate limit' do
      let(:request_count) { 301 }

      it { is_expected.to(have_http_status(:too_many_requests)) }
      it { expect(response.headers['Retry-After']).to(eq('60')) }
      it { expect(json).to(include('error' => include('code' => -32_000, 'message' => be_present), 'jsonrpc' => '2.0')) }
    end

    context 'when the API key user prefers Spanish' do
      let(:api_key) { create(:api_key, user: create(:customer_user, locale: 'es')) }

      it { expect(json.dig('result', 'tools').pluck('description')).to(include(Types::Translation.call(:fields, :query, :shipments))) }
    end

    context 'with a customer calling get_shipment' do
      let(:params) { { arguments: { id: shipment.load_id.to_s }, name: 'get_shipment' } }
      let(:rpc_method) { 'tools/call' }
      let(:shipment) { create(:shipment, broker_customer: api_key.user.companyable) }
      let(:shipment_json) { JSON.parse(json.dig('result', 'content', 0, 'text')).dig('data', 'shipment') }

      it { expect(json.dig('result', 'isError')).to(be(false)) }
      it { expect(shipment_json['loadId']).to(eq(shipment.load_id)) }
      it { expect(shipment_json).not_to(include('carrierCostCents', 'carrierCostCurrency', 'totalCostCents', 'totalCostCurrency')) }
    end

    context 'with a broker calling get_shipment' do
      let(:api_key) { create(:api_key, user: create(:root_broker_user)) }
      let(:params) { { arguments: { id: shipment.load_id.to_s }, name: 'get_shipment' } }
      let(:rpc_method) { 'tools/call' }
      let(:shipment) { create(:shipment) }
      let(:shipment_json) { JSON.parse(json.dig('result', 'content', 0, 'text')).dig('data', 'shipment') }

      it { expect(shipment_json).to(include('carrierCostCents' => shipment.carrier_cost_cents)) }
    end

    context 'with a customer running a GraphQL query for a hidden field' do
      let(:params) { { arguments: { query: '{ shipments { items { carrierCostCents } } }' }, name: 'graphql_query' } }
      let(:rpc_method) { 'tools/call' }

      it { expect(json.dig('result', 'isError')).to(be(true)) }
      it { expect(JSON.parse(json.dig('result', 'content', 0, 'text'))['data']).to(be_nil) }
    end

    context 'with an initialize request' do
      let(:params) { { capabilities: {}, clientInfo: { name: 'rspec', version: '1.0' }, protocolVersion: '2025-06-18' } }
      let(:rpc_method) { 'initialize' }
      let(:server_info) { json.dig('result', 'serverInfo') }

      it { expect(server_info).to(include('name' => MCPController.server_name, 'title' => "#{Setting.value!(:name)} TMS")) }
      it { expect(json.dig('result', 'instructions')).to(include(Setting.value!(:name), 'www.example.com', 'get_shipment')) }
    end

    context 'with invalid JSON' do
      let(:body) { '{' }
      let(:headers) { { 'Authorization' => "Bearer #{api_key.token}", 'Content-Type' => 'text/plain' } }

      it { expect(json.dig('error', 'code')).to(eq(-32_700)) }
    end

    context 'with a missing argument' do
      let(:params) { { arguments: {}, name: 'get_shipment' } }
      let(:rpc_method) { 'tools/call' }

      it { expect(json.dig('result', 'isError')).to(be(true)) }
    end

    context 'with a notification' do
      let(:body) { { jsonrpc: '2.0', method: 'notifications/initialized' }.to_json }

      it { is_expected.to(have_http_status(:accepted)) }
    end

    context 'with an unknown API key' do
      let(:headers) { { 'Authorization' => 'Bearer tms_unknown', 'Content-Type' => 'application/json' } }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'without credentials' do
      let(:headers) { { 'Content-Type' => 'application/json' } }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json['error']).to(be_present) }
    end
  end
end
