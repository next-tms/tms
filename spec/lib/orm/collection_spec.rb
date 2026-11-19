require 'rails_helper'

RSpec.describe(ORM::Collection) do
  let(:collection) { Grid::ORM::Region.all }
  let(:country) { Grid::ORM::Country.find('US') }

  describe '#initialize' do
    it { expect { described_class.new(String, []) }.to(raise_error(ArgumentError)) }
  end

  describe '#find' do
    it { expect(collection.find('US-CA').name).to(eq('California')) }
    it { expect { collection.find('ZZ-QQ') }.to(raise_error(ActiveRecord::RecordNotFound)) }
  end

  describe '#find_by' do
    it { expect(collection.find_by(abbreviation: 'CA', country:).iso31662).to(eq('US-CA')) }
    it { expect(collection.find_by(iso31662: 'US-TX').name).to(eq('Texas')) }
    it { expect(collection.find_by(iso31662: 'ZZ-QQ')).to(be_nil) }
  end

  describe '#find_by!' do
    it { expect(collection.find_by!(iso31662: 'US-TX').name).to(eq('Texas')) }
    it { expect { collection.find_by!(iso31662: 'ZZ-QQ') }.to(raise_error(ActiveRecord::RecordNotFound)) }
  end

  describe '#inspect' do
    it { expect(collection.inspect).to(eq('#<ORM::Collection orm_class=Grid::ORM::Region size=6>')) }
  end

  describe '#order' do
    it { expect(collection.order(:name).pluck(:name).first(3)).to(eq(['Aguascalientes', 'British Columbia', 'California'])) }
    it { expect(collection.order(:name)).to(be_a(described_class)) }
  end

  describe '#pluck' do
    it { expect(collection.where(country:).pluck(:abbreviation)).to(eq(['CA', 'TX', 'WY'])) }
  end

  describe '#to_ary' do
    it { expect([country] + country.regions).to(eq([country, *country.regions.to_a])) }
  end

  describe '#where' do
    it { expect(collection.where).to(equal(collection)) }
    it { expect(collection.where(abbreviation: 'CA').pluck(:iso31662)).to(eq(['US-CA'])) }
    it { expect(collection.where(abbreviation: ['BC', 'CA']).pluck(:iso31662)).to(eq(['CA-BC', 'US-CA'])) }
    it { expect(collection.where(country:, iso31662: ['CA-ON', 'US-TX', 'ZZ-QQ']).pluck(:iso31662)).to(eq(['US-TX'])) }
    it { expect(collection.where(iso31662: ['US-TX', 'MX-AGU']).pluck(:iso31662)).to(eq(['US-TX', 'MX-AGU'])) }
    it { expect(collection.where(iso31662: 'ZZ-QQ')).to(be_empty) }
  end
end
