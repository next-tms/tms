require 'rails_helper'

RSpec.describe(Types::Iso31662Type) do
  describe '.enum_values' do
    it { expect(described_class.enum_values.map(&:graphql_name)).to(include('US_CA', 'MX_AGU')) }
    it { expect(described_class.enum_values.find { |value| value.graphql_name == 'US_CA' }.value).to(eq('US-CA')) }

    context 'when a code is not a valid GraphQL name' do
      before do
        original_hash = JSON.parse(TransponderCountries::FIXTURE_PATH.read)
        original_hash.dig('data',
                          'fetchCountries').last['regions'] << { 'abbreviation' => 'X1~', 'iso31662' => 'US-X1~', 'name' => 'Placeholder' }

        stub_transponder_countries(original_hash)
      end

      it { expect(described_class.enum_values.map(&:value)).not_to(include('US-X1~')) }
      it { expect(described_class.enum_values.size).to(eq(6)) }
    end
  end
end
