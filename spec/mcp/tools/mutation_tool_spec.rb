require 'rails_helper'

RSpec.describe(Tools::MutationTool) do
  let(:tool) { Class.new(described_class) { root_field :fetch_rates } }

  describe '.arguments_schema' do
    subject(:schema) { tool.arguments_schema }

    it { expect(schema[:properties].keys).to(eq(%i[carrier_account_id declared_freight_classes shipment_load_id])) }
    it { expect(schema[:required]).to(eq([:shipment_load_id])) }
  end

  describe '.inherited' do
    subject { tool.annotations.to_h }

    it { is_expected.to(eq(destructiveHint: true, idempotentHint: false, openWorldHint: true, readOnlyHint: false)) }
  end

  describe '.operation_type' do
    subject { tool.operation_type }

    it { is_expected.to(eq('mutation')) }
  end

  describe '.root_type' do
    subject { tool.root_type }

    it { is_expected.to(eq(Types::MutationType)) }
  end

  describe '.selection_depth' do
    subject { tool.selection_depth }

    it { is_expected.to(eq(2)) }
  end

  describe '.variables' do
    subject { tool.variables(shipment_load_id: '1') }

    it { is_expected.to(eq('input' => { 'shipmentLoadId' => '1' })) }
  end
end
