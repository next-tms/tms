require 'rails_helper'

RSpec.describe(Tools::GraphQLSchema) do
  let(:authorizable) { create(:root_broker_user) }
  let(:profile) { described_class.profile_for(authorizable:) }
  let(:printer) { GraphQL::Schema::Printer.new(LiftoffSchema, context: { authorizable: }) }

  describe '.call' do
    subject(:tool_response) { described_class.call(server_context: { authorizable: }, type_name:) }

    let(:text) { tool_response.content.first[:text] }
    let(:type_name) { nil }

    it { is_expected.not_to(be_error) }
    it { expect(text).to(include('type Query {', 'type Mutation {', 'Types: Address, ')) }

    context 'with a type name' do
      let(:type_name) { 'Shipment' }

      it { expect(text).to(start_with('"""').and(include('type Shipment', 'carrierCostCents'))) }
    end

    context 'when the user is a customer' do
      let(:authorizable) { create(:customer_user) }
      let(:type_name) { 'Shipment' }

      it { expect(text).to(include('type Shipment')) }
      it { expect(text).not_to(include('carrierCostCents', 'totalCostCents')) }
    end

    context 'with a filter type name' do
      let(:type_name) { 'ShipmentFilter' }

      it { expect(text).to(start_with('input ShipmentFilter: ')) }
    end

    context 'with an unknown type name' do
      let(:type_name) { 'Unknown' }

      it { is_expected.to(be_error) }
      it { expect(text).to(include('Unknown')) }
    end
  end

  describe '.describe' do
    subject { described_class.describe(type, profile, printer) }

    let(:type) { Types::CarrierType }

    it { is_expected.to(include('type Carrier', 'legalName')) }

    context 'with a filter type' do
      let(:type) { Types::CarrierFilterType }

      it { is_expected.to(start_with('input CarrierFilter: ')) }
    end
  end

  describe '.overview' do
    subject { described_class.overview(profile, printer) }

    it { is_expected.to(include('type Query {', 'type Mutation {')) }
    it { is_expected.not_to(include('__Schema')) }
  end

  describe '.to_h' do
    subject { described_class.to_h }

    it { is_expected.to(include(annotations: include(readOnlyHint: true), name: 'graphql_schema')) }
  end
end
