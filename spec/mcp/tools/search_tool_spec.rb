require 'rails_helper'

RSpec.describe(Tools::SearchTool) do
  let(:tool) { Class.new(described_class) { root_field :shipments } }

  describe '.arguments_schema' do
    subject(:schema) { tool.arguments_schema }

    it { expect(schema[:properties].keys).to(eq(%i[page page_size sort filter])) }
    it { expect(schema[:properties][:filter]).to(include(type: 'object')) }
    it { expect(schema[:properties][:page_size]).to(eq(maximum: 100, minimum: 1, type: 'integer')) }
    it { expect(schema[:required]).to(be_empty) }
  end

  describe '.inherited' do
    subject { tool.annotations.to_h }

    it { is_expected.to(eq(destructiveHint: false, idempotentHint: true, openWorldHint: false, readOnlyHint: true)) }
  end

  describe '.selection_depth' do
    subject { tool.selection_depth }

    it { is_expected.to(eq(1)) }
  end
end
