require 'rails_helper'

RSpec.describe(Accessorial) do
  let(:broker_customer) { create(:broker_customer) }

  describe '.catalog' do
    subject(:catalog) { described_class.catalog }

    it { expect(catalog.size).to(eq(Transponder::ORM::Accessorial.all.size)) }
    it { expect(catalog).to(all(be_new_record)) }
    it { expect(catalog.map(&:name)).to(eq(catalog.map(&:name).sort)) }

    it do
      expect(catalog.find do |accessorial|
        accessorial.transponder_code == 'liftgate_delivery'
      end).to(have_attributes(broker_only: false, name: 'Liftgate Delivery'))
    end

    context 'when an accessorial overrides a Transponder accessorial' do
      let!(:liftgate) { create(:accessorial, code: nil, name: 'Lift gate', transponder_code: 'liftgate_delivery') }

      it { is_expected.to(include(liftgate)) }
      it { expect(catalog.count { |accessorial| accessorial.transponder_code == 'liftgate_delivery' }).to(eq(1)) }
    end

    context 'with a custom accessorial' do
      let!(:custom) { create(:accessorial, code: 'WKND', name: 'Weekend Holding') }

      it { is_expected.to(include(custom)) }
      it { expect(catalog.size).to(eq(Transponder::ORM::Accessorial.all.size + 1)) }
    end

    context 'when scoped to a broker customer' do
      subject(:catalog) { described_class.eligible(broker_customer:).catalog }

      let!(:customer) { create(:accessorial, broker_customer:, code: 'CURB', name: 'Curbside') }

      before { create(:accessorial, broker_customer: create(:broker_customer), code: 'THRD', name: 'Threshold') }

      it { is_expected.to(include(customer)) }
      it { expect(catalog.map(&:code)).not_to(include('THRD')) }
    end
  end

  describe '.eligible' do
    let!(:blanket) { create(:accessorial, broker_customer: nil, code: 'LFT') }
    let!(:overridden) { create(:accessorial, broker_customer: nil, code: 'RES') }

    before { create(:accessorial, broker_customer: create(:broker_customer), code: 'OTH') }

    it { expect(described_class.eligible).to(contain_exactly(blanket, overridden)) }

    context 'with a broker customer' do
      let!(:customer) { create(:accessorial, broker_customer:, code: 'RES') }

      it { expect(described_class.eligible(broker_customer:)).to(contain_exactly(blanket, customer)) }
    end

    context 'when the broker customer overrides a Transponder accessorial' do
      let!(:customer) { create(:accessorial, broker_customer:, code: 'CLIF', transponder_code: 'liftgate_delivery') }

      before { blanket.update!(transponder_code: 'liftgate_delivery') }

      it { expect(described_class.eligible(broker_customer:)).to(contain_exactly(customer, overridden)) }
    end
  end

  describe '.offered' do
    let!(:custom) { create(:accessorial, code: 'DREW') }
    let!(:transponder) { create(:accessorial, broker_only: true, code: 'TRSD', transponder_code: 'convention_delivery') }

    before { create(:accessorial, broker_only: true, code: 'IZZY') }

    it { expect(described_class.offered).to(contain_exactly(custom, transponder)) }
  end

  describe '.with_transponder_codes' do
    subject(:accessorials) { described_class.with_transponder_codes(['residential_delivery', :liftgate_delivery, 'unknown']) }

    let!(:liftgate) { create(:accessorial, code: 'DLIF', transponder_code: 'liftgate_delivery') }

    it { expect(accessorials.map(&:transponder_code)).to(eq(['residential_delivery', 'liftgate_delivery'])) }
    it { expect(accessorials.first).to(be_new_record) }
    it { expect(accessorials.last).to(eq(liftgate)) }

    context 'when several accessorials share a Transponder code' do
      before do
        create(:accessorial, broker_only: true, code: 'ALIF', transponder_code: 'liftgate_delivery')
        create(:accessorial, code: 'ZLIF', transponder_code: 'liftgate_delivery')
      end

      it { expect(accessorials.last).to(eq(liftgate)) }
    end

    context 'with a broker customer' do
      subject(:accessorials) { described_class.with_transponder_codes(:liftgate_delivery, broker_customer:) }

      let!(:customer) { create(:accessorial, broker_customer:, code: 'CLIF', transponder_code: 'liftgate_delivery') }

      it { is_expected.to(eq([customer])) }
    end
  end

  describe '#cache_version' do
    let(:accessorial) { create(:accessorial) }

    it { expect(accessorial.cache_version).to(eq(accessorial.updated_at.utc.to_fs(:usec))) }
    it { expect(build(:accessorial, transponder_code: 'liftgate_delivery').cache_version).to(eq('liftgate_delivery')) }
  end

  describe '#key' do
    let(:accessorial) { create(:accessorial) }

    it { expect(accessorial.key).to(eq(accessorial.id.to_s)) }
    it { expect(build(:accessorial, transponder_code: 'liftgate_delivery').key).to(eq('liftgate_delivery')) }
  end

  describe '#offered?' do
    it { expect(build(:accessorial, broker_only: false)).to(be_offered) }
    it { expect(build(:accessorial, broker_only: true, transponder_code: 'convention_delivery')).to(be_offered) }
    it { expect(build(:accessorial, broker_only: true)).not_to(be_offered) }
  end

  describe '#overrides?' do
    let(:accessorial) { build(:accessorial, code: 'DLIF', transponder_code: 'liftgate_delivery') }

    it { expect(accessorial.overrides?(build(:accessorial, code: 'DLIF'))).to(be(true)) }
    it { expect(accessorial.overrides?(build(:accessorial, code: 'LIFT', transponder_code: 'liftgate_delivery'))).to(be(true)) }
    it { expect(accessorial.overrides?(build(:accessorial, code: 'DRES', transponder_code: 'residential_delivery'))).to(be(false)) }
    it { expect(build(:accessorial, code: nil, transponder_code: nil).overrides?(build(:accessorial, code: nil))).to(be(false)) }
  end

  describe '#transponder_accessorial' do
    let(:accessorial) { build(:accessorial, transponder_code: 'liftgate_delivery') }

    it { expect(accessorial.transponder_accessorial).to(have_attributes(code: 'liftgate_delivery')) }
    it { expect(build(:accessorial, transponder_code: nil).transponder_accessorial).to(be_nil) }
  end

  describe 'validations' do
    it { expect(build(:accessorial, code: nil)).not_to(be_valid) }
    it { expect(build(:accessorial, code: nil, transponder_code: 'liftgate_delivery')).to(be_valid) }
    it { expect(build(:accessorial, name: nil)).not_to(be_valid) }
    it { expect(build(:accessorial, transponder_code: 'unknown')).not_to(be_valid) }
  end
end
