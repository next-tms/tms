require 'rails_helper'

RSpec.describe(Accounting) do
  describe('.money') do
    it { expect(described_class.money(0)).to(eq(Money.new(0))) }
    it { expect(described_class.money(148)).to(eq(Money.new(148))) }
    it { expect(described_class.money(BigDecimal('258.99'))).to(eq(Money.new(25_899))) }
    it { expect(described_class.money(nil)).to(be_nil) }
  end
end
