require 'rails_helper'

RSpec.describe(ORM::Base) do
  let(:country) { Grid::ORM::Country.find('US') }

  describe '.all' do
    it { expect { described_class.all }.to(raise_error(NotImplementedError)) }
  end

  describe '.find_or_initialize_by' do
    it { expect(Grid::ORM::Country.find_or_initialize_by(alpha2: 'US')).to(equal(country)) }
    it { expect(Grid::ORM::Country.find_or_initialize_by(alpha2: 'ZZ')).not_to(be_in(Grid::ORM::Country.all)) }
    it { expect(Grid::ORM::Country.find_or_initialize_by(alpha2: 'ZZ').alpha2).to(eq('ZZ')) }
  end

  describe '.model_name' do
    it { expect(Grid::ORM::Country.model_name.name).to(eq('Grid::ORM::Country')) }
  end

  describe '.order' do
    it { expect(Grid::ORM::Country.order(:name).pluck(:alpha2)).to(eq(['CA', 'MX', 'US'])) }
  end

  describe '.primary_key' do
    it { expect { described_class.primary_key }.to(raise_error(NotImplementedError)) }
  end

  describe '#==' do
    it { expect(country).to(eq(Grid::ORM::Country.new(alpha2: 'US'))) }
    it { expect(country).not_to(eq(Grid::ORM::Country.find('CA'))) }
    it { expect(country).not_to(eq(Grid::ORM::Region.new(iso31662: 'US'))) }
  end

  describe '#cache_key' do
    it { expect(country.cache_key).to(eq('grid/orm/countries/US')) }
  end

  describe '#cache_key_with_version' do
    it { expect(country.cache_key_with_version).to(eq("grid/orm/countries/US-#{country.cache_version}")) }
  end

  describe '#cache_version' do
    it { expect { described_class.new.cache_version }.to(raise_error(NotImplementedError)) }
  end

  describe '#hash' do
    it { expect(country.hash).to(eq(Grid::ORM::Country.new(alpha2: 'US').hash)) }
  end

  describe '#id' do
    it { expect(country.id).to(eq('US')) }
  end

  describe '#inspect' do
    it { expect(country.inspect).to(eq('#<Grid::ORM::Country id=US>')) }
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

  describe '#updated_at' do
    it { expect(country.updated_at).to(be_nil) }
  end
end
