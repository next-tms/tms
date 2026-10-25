require 'rails_helper'

RSpec.describe(Types::Iso31661Alpha3Type) do
  describe '.enum_values' do
    it { expect(described_class.enum_values.map(&:graphql_name)).to(eq(%w[CAN MEX USA])) }
    it { expect(described_class.enum_values.map(&:value)).to(eq(%w[CAN MEX USA])) }
  end
end
