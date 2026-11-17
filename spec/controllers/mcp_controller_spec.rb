require 'rails_helper'

RSpec.describe(MCPController) do
  describe '.server_name' do
    subject { described_class.server_name }

    before { create(:setting, key: 'name', value: 'Example Freight, Inc.') }

    it { is_expected.to(eq('example-freight-inc')) }
  end
end
