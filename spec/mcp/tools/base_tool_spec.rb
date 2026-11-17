require 'rails_helper'

RSpec.describe(Tools::BaseTool) do
  let(:authorizable) { create(:root_broker_user) }
  let(:profile) { tool.profile_for(server_context) }
  let(:server_context) { { authorizable:, session: {} } }
  let(:shipment) { create(:shipment) }
  let(:tool) { Class.new(described_class) { root_field :shipment } }

  describe '.arguments_schema' do
    subject { tool.arguments_schema }

    it { is_expected.to(eq(properties: { id: { type: 'string' } }, required: [:id], type: 'object')) }
  end

  describe '.call' do
    subject(:tool_response) { tool.call(id: shipment.load_id.to_s, server_context:) }

    let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'shipment') }

    it { is_expected.not_to(be_error) }
    it { expect(data['loadId']).to(eq(shipment.load_id)) }
    it { expect(data['carrierCostCents']).to(eq(shipment.carrier_cost_cents)) }

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user, companyable: shipment.broker_customer) }

      it { expect(data['loadId']).to(eq(shipment.load_id)) }
      it { expect(data).not_to(include('carrierCostCents', 'totalCostCents')) }
    end
  end

  describe '.description_value' do
    subject { tool.description_value }

    it { is_expected.to(eq(Types::Translation.call(:fields, :query, :shipment))) }

    context 'without a root field' do
      let(:tool) { Class.new(described_class) { description 'Explicit' } }

      it { is_expected.to(eq('Explicit')) }
    end
  end

  describe '.document' do
    subject { tool.document(profile) }

    it { is_expected.to(start_with('query($id: ID!) { shipment(id: $id) { appliedRateId bol ')) }
    it { is_expected.to(include('carrierCostCents')) }
    it { is_expected.not_to(include('receiverAddress')) }
  end

  describe '.execute' do
    subject(:tool_response) { tool.execute(query, context: server_context) }

    let(:query) { '{ __typename }' }

    it { is_expected.not_to(be_error) }
    it { expect(tool_response.content).to(eq([{ text: '{"data":{"__typename":"Query"}}', type: 'text' }])) }

    context 'with an invalid query' do
      let(:query) { '{ unknownField }' }

      it { is_expected.to(be_error) }
    end
  end

  describe '.operation_type' do
    subject { tool.operation_type }

    it { is_expected.to(eq('query')) }
  end

  describe '.profile_for' do
    subject { profile.fields(Types::ShipmentType).map(&:graphql_name) }

    it { is_expected.to(include('carrierCostCents')) }

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.not_to(include('carrierCostCents')) }
    end
  end

  describe '.root_field' do
    subject { tool.field.graphql_name }

    it { is_expected.to(eq('shipment')) }
    it { expect(tool.input_schema.to_h[:required]).to(eq(['id'])) }
  end

  describe '.root_type' do
    subject { tool.root_type }

    it { is_expected.to(eq(Types::QueryType)) }
  end

  describe '.selection' do
    subject { tool.selection(type, profile, depth:) }

    let(:depth) { 0 }
    let(:type) { Types::CarrierType }

    it { is_expected.to(eq('id legalName mcNumber name scac')) }

    context 'with a nested object type' do
      let(:depth) { 1 }
      let(:type) { Types::BillType }

      it { is_expected.to(include('shipment { appliedRateId ')) }
    end

    context 'with a field that takes arguments' do
      let(:depth) { 1 }

      it { is_expected.not_to(include('accounts')) }
    end
  end

  describe '.selection_depth' do
    subject { tool.selection_depth }

    it { is_expected.to(eq(0)) }
  end

  describe '.variables' do
    subject { tool.variables(filter: { load_id_eq: 1 }, page: nil) }

    it { is_expected.to(eq('filter' => { 'loadIdEq' => 1 })) }
  end
end
