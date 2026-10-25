require 'rails_helper'

RSpec.describe(TransponderService::Input::Location) do
  describe '.call' do
    let(:address) { build(:address, country_alpha2: 'CA', region_iso31662: 'CA-ON', zip_code: 'K1A 0B1') }
    let(:result) { described_class.call(address, contactable: nil) }

    it { expect(result['country']).to(eq({ 'alpha3' => 'CAN' })) }
    it { expect(result['regionAbbreviation']).to(eq('ON')) }
  end
end
