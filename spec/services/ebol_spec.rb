require 'rails_helper'

RSpec.describe(EBOL) do
  describe '.accessorial_code' do
    it { expect(described_class.accessorial_code('liftgate_delivery')).to(eq('LFTD')) }
    it { expect(described_class.accessorial_code('unknown')).to(be_nil) }
  end

  describe '.accessorial_codes' do
    let(:accessorials) { [build(:accessorial, transponder_code: 'liftgate_delivery'), build(:accessorial, transponder_code: 'unknown')] }

    it { expect(described_class.accessorial_codes(accessorials)).to(eq(['LFTD'])) }
  end

  describe '.freight_kit_type' do
    it { expect(described_class.freight_kit_type('pat')).to(eq('pallet')) }
    it { expect(described_class.freight_kit_type('SKD')).to(eq('pallet')) }
    it { expect(described_class.freight_kit_type('BAG')).to(eq('piece')) }
  end

  describe '.handling_unit_type' do
    it { expect(described_class.handling_unit_type(build(:packaging, freight_kit_type: 'pallet'))).to(eq('PAT')) }
    it { expect(described_class.handling_unit_type(build(:packaging, freight_kit_type: nil))).to(eq('OTH')) }
    it { expect(described_class.handling_unit_type(nil)).to(eq('OTH')) }
  end

  describe '.transponder_code' do
    it { expect(described_class.transponder_code('RES')).to(eq('residential_delivery')) }
    it { expect(described_class.transponder_code('XYZ')).to(be_nil) }
  end

  describe '.valid?' do
    let(:document) { JSON.parse(file_fixture('dsdc/bol_request.json').read) }

    it { expect(described_class.valid?(document)).to(be(true)) }
    it { expect(described_class.valid?(document.symbolize_keys)).to(be(true)) }
    it { expect(described_class.valid?(document.except('origin'))).to(be(false)) }
    it { expect(described_class.valid?(document.deep_merge('bol' => { 'isTest' => 'yes' }))).to(be(false)) }
  end

  describe 'DELIVERY_ACCESSORIAL_CODES' do
    it { expect(described_class::DELIVERY_ACCESSORIAL_CODES).to(eq(['APTD', 'GTD_AM', 'GTD_PM', 'IDL', 'LFTD', 'LTDAD', 'MNC', 'RES'])) }
  end
end
