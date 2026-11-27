require 'rails_helper'

RSpec.describe(Transponder::ORM::Accessorial) do
  let(:accessorial) { described_class.new(code: 'liftgate_delivery') }

  describe '.all' do
    it { expect(described_class.pluck(:code)).to(include('liftgate_delivery', 'residential_pickup')) }
    it { expect(described_class.pluck(:code)).to(all(match(/\A[a-z_]+\z/))) }
  end

  describe '.find_by' do
    it { expect(described_class.find_by(code: 'liftgate_delivery')).to(eq(accessorial)) }
    it { expect(described_class.find_by(code: 'unknown')).to(be_nil) }
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:code)) }
  end

  describe '#cache_version' do
    it { expect(accessorial.cache_version).to(eq('liftgate_delivery')) }
  end

  describe '#name' do
    it { expect(accessorial.name).to(eq('Liftgate Delivery')) }
  end
end
