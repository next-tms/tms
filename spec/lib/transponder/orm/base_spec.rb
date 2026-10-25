require 'rails_helper'

RSpec.describe(Transponder::ORM::Base) do
  let(:country) { Transponder::ORM::Country.find('US') }

  describe '.all' do
    it { expect { described_class.all }.to(raise_error(NotImplementedError)) }
  end

  describe '.find_or_initialize_by' do
    it { expect(Transponder::ORM::Country.find_or_initialize_by(alpha2: 'US')).to(equal(country)) }
    it { expect(Transponder::ORM::Country.find_or_initialize_by(alpha2: 'ZZ')).not_to(be_in(Transponder::ORM::Country.all)) }
    it { expect(Transponder::ORM::Country.find_or_initialize_by(alpha2: 'ZZ').alpha2).to(eq('ZZ')) }
  end

  describe '.model_name' do
    it { expect(Transponder::ORM::Country.model_name.name).to(eq('Transponder::ORM::Country')) }
  end

  describe '.order' do
    it { expect(Transponder::ORM::Country.order(:name).pluck(:alpha2)).to(eq(%w[CA MX US])) }
  end

  describe '.primary_key' do
    it { expect { described_class.primary_key }.to(raise_error(NotImplementedError)) }
  end

  describe '#==' do
    it { expect(country).to(eq(Transponder::ORM::Country.new(alpha2: 'US'))) }
    it { expect(country).not_to(eq(Transponder::ORM::Country.find('CA'))) }
    it { expect(country).not_to(eq(Transponder::ORM::Region.new(iso31662: 'US'))) }
  end

  describe '#hash' do
    it { expect(country.hash).to(eq(Transponder::ORM::Country.new(alpha2: 'US').hash)) }
  end

  describe '#id' do
    it { expect(country.id).to(eq('US')) }
  end

  describe '#inspect' do
    it { expect(country.inspect).to(eq('#<Transponder::ORM::Country id=US>')) }
  end

  describe '#persisted?' do
    it { expect(country).to(be_persisted) }
  end

  describe '#to_model' do
    it { expect(country.to_model).to(equal(country)) }
  end

  describe '#to_param' do
    it { expect(country.to_param).to(eq('US')) }
  end
end
