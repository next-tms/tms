require 'rails_helper'

RSpec.describe(Tools::GetTool) do
  let(:tool) { Class.new(described_class) }

  describe '.inherited' do
    subject { tool.annotations.to_h }

    it { is_expected.to(eq(destructiveHint: false, idempotentHint: true, openWorldHint: false, readOnlyHint: true)) }
  end

  describe '.selection_depth' do
    subject { tool.selection_depth }

    it { is_expected.to(eq(1)) }
  end
end
