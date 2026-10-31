require 'rails_helper'

RSpec.describe(Transponder::ORM::Region) do
  let(:california) { described_class.find('US-CA') }
  let(:unknown) { described_class.new(iso31662: 'ZZ-QQ') }

  describe '.all' do
    it { expect(described_class.pluck(:iso31662)).to(eq(['CA-BC', 'CA-ON', 'MX-AGU', 'US-CA', 'US-TX', 'US-WY'])) }
    it { expect(described_class.all).to(equal(described_class.all)) }

    context 'when the country collection is older than MEMO_EXPIRES_IN' do
      let!(:collection) { described_class.all }

      before { Timecop.travel(Transponder::ORM::Country::MEMO_EXPIRES_IN.from_now + 1.second) }
      after { Timecop.return }

      it { expect(described_class.all).not_to(equal(collection)) }
      it { expect(described_class.first.country).to(equal(Transponder::ORM::Country.find('CA'))) }
    end

    context 'when it was last built from another country collection' do
      let!(:collection) { described_class.all }

      before { Transponder::ORM::Country.instance_variable_set(:@all, nil) }

      it { expect(described_class.all).not_to(equal(collection)) }
      it { expect(described_class.first.country).to(equal(Transponder::ORM::Country.find('CA'))) }
    end
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:iso31662)) }
  end

  describe '#abbreviation' do
    it { expect(california.abbreviation).to(eq('CA')) }
    it { expect(unknown.abbreviation).to(eq('QQ')) }
  end

  describe '#country' do
    it { expect(california.country).to(equal(Transponder::ORM::Country.find('US'))) }
    it { expect(described_class.new(iso31662: 'US-ZZ').country).to(equal(Transponder::ORM::Country.find('US'))) }
    it { expect(unknown.country.alpha2).to(eq('ZZ')) }
  end

  describe '#name' do
    it { expect(california.name).to(eq('California')) }
    it { expect(unknown.name).to(eq('ZZ-QQ')) }
  end
end
