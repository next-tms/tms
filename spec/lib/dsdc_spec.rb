require 'rails_helper'

RSpec.describe(DSDC) do
  describe '.boolean' do
    it { expect(described_class.boolean('False')).to(be(false)) }
    it { expect(described_class.boolean('TRUE')).to(be(true)) }
    it { expect(described_class.boolean(true)).to(be(true)) }
  end
end
