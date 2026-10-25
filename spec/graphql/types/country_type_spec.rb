require 'rails_helper'

RSpec.describe(Types::CountryType) do
  describe 'fields' do
    it { expect(described_class.fields['alpha2Code'].method_sym).to(eq(:alpha2)) }
    it { expect(described_class.fields['alpha3Code'].method_sym).to(eq(:alpha3)) }
    it { expect(described_class.fields['alpha3Code'].type.graphql_name).to(eq('Iso31661Alpha3')) }
    it { expect(described_class.fields['unCode'].method_sym).to(eq(:numeric)) }
    it { expect(described_class.fields['unCode'].type.graphql_name).to(eq('Int')) }
    it { expect(described_class.fields).not_to(include('createdAt', 'updatedAt')) }
  end
end
