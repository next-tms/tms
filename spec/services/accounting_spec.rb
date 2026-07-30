require 'rails_helper'

RSpec.describe(Accounting) do
  describe('.money') do
    it { expect(described_class.money(0)).to(eq(Money.new(0))) }
    it { expect(described_class.money(148)).to(eq(Money.new(148))) }
    it { expect(described_class.money(BigDecimal('258.99'))).to(eq(Money.new(25_899))) }
    it { expect(described_class.money(nil)).to(be_nil) }
  end

  describe('.record_class') do
    before { create(:integration, :wave, credentials: { access_token: 'access', business_id: 'biz' }) }

    it { expect(described_class.record_class(:customer)).to(eq(Accounting::Wave::Customer)) }
    it { expect { described_class.record_class(:bill) }.to(raise_error(Accounting::UnsupportedResource)) }
  end

  describe('.supports?') do
    before { create(:integration, :wave, credentials: { access_token: 'access', business_id: 'biz' }) }

    it { expect(described_class.supports?(:customer)).to(be(true)) }
    it { expect(described_class.supports?(:vendor)).to(be(true)) }
    it { expect(described_class.supports?(:bill)).to(be(false)) }
    it { expect(described_class.supports?(:bill_payment)).to(be(false)) }
  end
end
