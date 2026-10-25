require 'rails_helper'

RSpec.describe(Mutations::AddressCreate) do
  let(:query) do
    <<~GRAPHQL
      mutation {
        addressCreate(input: { addressInput: { city: "Fremont", regionIso31662: #{region}, street: "4011 Lana Tier", zipCode: "94536" } }) {
          address {
            country { alpha2Code alpha3Code name unCode }
            region { abbreviation name }
          }
        }
      }
    GRAPHQL
  end

  let(:region) { 'US_CA' }
  let(:result) { LiftoffSchema.execute(query, context: {}).to_h }

  it { expect { result }.to(change(Address, :count).by(1)) }
  it { expect(result.dig('data', 'addressCreate', 'address', 'country', 'alpha2Code')).to(eq('US')) }
  it { expect(result.dig('data', 'addressCreate', 'address', 'country', 'unCode')).to(eq(840)) }
  it { expect(result.dig('data', 'addressCreate', 'address', 'region')).to(eq({ 'abbreviation' => 'CA', 'name' => 'California' })) }

  context 'when the region is not a known code' do
    let(:region) { 'US_ZZ' }

    it { expect(result['errors']).to(be_present) }
  end
end
