require 'rails_helper'

RSpec.describe(Tools::GraphQLQuery) do
  let(:authorizable) { create(:customer_user, companyable: shipment.broker_customer) }
  let(:shipment) { create(:shipment) }

  describe '.call' do
    subject(:tool_response) { described_class.call(query:, server_context: { authorizable: }, variables: { id: shipment.load_id.to_s }) }

    let(:query) { 'query($id: ID!) { shipment(id: $id) { loadId } }' }
    let(:result) { JSON.parse(tool_response.content.first[:text]) }

    it { is_expected.not_to(be_error) }
    it { expect(result.dig('data', 'shipment', 'loadId')).to(eq(shipment.load_id)) }

    context 'with a field hidden from the role' do
      let(:query) { 'query($id: ID!) { shipment(id: $id) { carrierCostCents } }' }

      it { is_expected.to(be_error) }
      it { expect(result['data']).to(be_nil) }
    end

    context 'with a mutation' do
      let(:query) { 'mutation($id: ID!) { fetchRates(input: { shipmentLoadId: $id }) { rates { id } } }' }

      before { allow(Shipment::RatesService).to(receive(:call)) }

      it { is_expected.to(be_error) }
      it { expect(tool_response.content.first[:text]).to(be_present) }

      it do
        tool_response

        expect(Shipment::RatesService).not_to(have_received(:call))
      end
    end
  end

  describe '.read_only?' do
    subject { described_class.read_only?(query, operation_name:) }

    let(:operation_name) { nil }
    let(:query) { '{ __typename }' }

    it { is_expected.to(be(true)) }

    context 'with a mutation' do
      let(:query) { 'mutation { fetchRates(input: { shipmentLoadId: "1" }) { rates { id } } }' }

      it { is_expected.to(be(false)) }
    end

    context 'with a named mutation among queries' do
      let(:operation_name) { 'Change' }
      let(:query) { 'query Read { __typename } mutation Change { fetchRates(input: { shipmentLoadId: "1" }) { rates { id } } }' }

      it { is_expected.to(be(false)) }
    end

    context 'with an unparsable query' do
      let(:query) { '{' }

      it { is_expected.to(be(true)) }
    end
  end

  describe '.to_h' do
    subject { described_class.to_h }

    it { is_expected.to(include(annotations: include(readOnlyHint: true), name: 'graphql_query')) }
  end
end
