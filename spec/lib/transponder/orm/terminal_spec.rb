require 'rails_helper'

RSpec.describe(Transponder::ORM::Terminal) do
  let(:terminal) { described_class.first }

  describe '.all' do
    it { expect(described_class.pluck(:phone)).to(eq(['+15125550100'])) }
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:id)) }
  end

  describe '#initialize' do
    it { expect(terminal.address.city).to(eq('Austin')) }
    it { expect(terminal.carrier).to(eq(Transponder::ORM::Carrier.find_by(scac: 'SAIA'))) }
    it { expect(described_class.new(id: 'bare').address).to(be_nil) }
  end
end
