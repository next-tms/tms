require 'rails_helper'

RSpec.describe(Types::Iso31661Alpha2Type) do
  let(:context) { GraphQL::Query::NullContext.instance }

  describe '.coerce_input' do
    it { expect(described_class.coerce_input('US', context)).to(eq('US')) }
    it { expect(described_class.validate_input('ZZ', context)).not_to(be_valid) }
  end

  describe '.coerce_result' do
    it { expect(described_class.coerce_result('US', context)).to(eq('US')) }
    it { expect(described_class.coerce_result('ZZ', context)).to(eq('ZZ')) }
  end

  describe '.enum_values' do
    it { expect(described_class.enum_values.map(&:graphql_name)).to(eq(%w[CA MX US])) }
    it { expect(described_class.enum_values.map(&:value)).to(eq(%w[CA MX US])) }
  end
end
