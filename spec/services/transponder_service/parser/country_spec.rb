require 'rails_helper'

RSpec.describe(TransponderService::Parser::Country) do
  describe '.call' do
    let(:united_states) { Grid::ORM::Country.find('US') }

    it { expect(described_class.call({ alpha2: 'US' })).to(equal(united_states)) }
    it { expect(described_class.call({ alpha2: 'US', alpha3: 'ROM' })).to(equal(united_states)) }
    it { expect(described_class.call({ alpha3: 'USA' })).to(equal(united_states)) }
    it { expect(described_class.call({ alpha2: 'ZZ' })).to(be_nil) }
    it { expect(described_class.call({})).to(be_nil) }
  end
end
