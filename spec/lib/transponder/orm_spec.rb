require 'rails_helper'

RSpec.describe(Transponder::ORM) do
  describe '.version' do
    it { expect(described_class.version).to(match(/\A\h{64}\z/)) }
    it { expect(described_class.version).to(equal(described_class.version)) }
  end
end
