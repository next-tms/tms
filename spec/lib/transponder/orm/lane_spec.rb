require 'rails_helper'

RSpec.describe(Transponder::ORM::Lane) do
  let(:lane) { described_class.find('3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01') }

  describe '.all' do
    it { expect(described_class.pluck(:id)).to(eq(['3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01', '7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02'])) }
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:id)) }
  end

  describe '#initialize' do
    it { expect(lane.carrier).to(eq(Transponder::ORM::Carrier.find_by(scac: 'SAIA'))) }
    it { expect(lane.destination.region_abbreviation).to(eq('TX')) }
    it { expect(lane.origin.region_abbreviation).to(eq('CA')) }
    it { expect(described_class.new(id: 'bare')).to(have_attributes(destination: nil, origin: nil)) }
  end

  describe '#name' do
    it { expect(lane.name).to(eq('CA, US → TX, US')) }
    it { expect(described_class.find('7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02').name).to(eq('US → AZ, US (850, 851)')) }
  end
end
