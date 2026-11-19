require 'rails_helper'

RSpec.describe(Grid::ORM::Country) do
  let(:canada) { described_class.find('CA') }
  let(:united_states) { described_class.find('US') }

  describe '.all' do
    it { expect(described_class.pluck(:alpha2)).to(eq(['CA', 'MX', 'US'])) }
    it { expect(described_class.all).to(equal(described_class.all)) }

    context 'when the collection is older than MEMO_EXPIRES_IN' do
      let!(:collection) { described_class.all }

      before { Timecop.travel(described_class::MEMO_EXPIRES_IN.from_now + 1.second) }
      after { Timecop.return }

      it { expect(described_class.all).not_to(equal(collection)) }
      it { expect(described_class.all).to(equal(described_class.all)) }
    end

    context 'when Grid returns errors' do
      before { stub_grid_countries({ 'errors' => [{ 'message' => 'Boom' }] }) }

      it { expect { described_class.all }.to(raise_error(GraphQL::Client::Error, 'Boom')) }
    end
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:alpha2)) }
  end

  describe '.find_by' do
    let(:error_response) { instance_double(GraphQL::Client::Response, original_hash: { 'errors' => [{ 'message' => 'Boom' }] }) }
    let(:named_query) { GraphQLClient::Grid::Query::FetchCountries::NAMED }

    it { expect(described_class.find_by(name: ' United States of America ')).to(equal(united_states)) }
    it { expect(described_class.find_by(name: 'can')).to(equal(canada)) }
    it { expect(described_class.find_by(name: 'Narnia')).to(be_nil) }
    it { expect(described_class.find_by(name: nil)).to(be_nil) }

    context 'when Grid returns errors' do
      before { allow(GraphQLClient::Grid::Client).to(receive(:query).with(named_query, variables: anything).and_return(error_response)) }

      it { expect { described_class.find_by(name: 'Canada') }.to(raise_error(GraphQL::Client::Error, 'Boom')) }
    end

    context 'when the name was resolved before' do
      before do
        allow(Rails).to(receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new))
        described_class.find_by(name: 'Canada')
        described_class.find_by(name: 'canada')
      end

      it { expect(GraphQLClient::Grid::Client).to(have_received(:query).with(named_query, variables: { name: 'Canada' }).once) }
    end
  end

  describe '.reset' do
    it { expect { described_class.reset }.to(change { described_class.all.object_id }) }
    it { expect { described_class.reset }.to(change { Grid::ORM::Region.all.object_id }) }
  end

  describe '#cache_version' do
    it { expect(united_states.cache_version).to(eq('United States of America/true/(\d{5})(?:[ \-](\d{4}))?/ZIP')) }
  end

  describe '#format_address' do
    it { expect(united_states.format_address('')).to(be_nil) }
    it { expect(united_states.format_address('1 Main St, Los Angeles, CA 90001')).to(eq('1 Main St, Los Angeles, CA 90001')) }
  end

  describe '#initialize' do
    it { expect(united_states.alpha3).to(eq('USA')) }
    it { expect(united_states.numeric).to(eq(840)) }
    it { expect(united_states.postal_code).to(be(true)) }
    it { expect(united_states.postal_code_format).to(eq('(\d{5})(?:[ \-](\d{4}))?')) }
    it { expect(described_class.new(alpha2: 'ZZ').postal_code).to(be(true)) }
    it { expect(described_class.new(alpha2: 'ZZ').postal_code_format).to(be_nil) }
    it { expect(described_class.new(alpha2: 'ZZ').postal_code_label).to(be_nil) }
    it { expect(united_states.postal_code_label).to(eq('ZIP')) }
    it { expect(united_states.regions.pluck(:iso31662)).to(eq(['US-CA', 'US-TX', 'US-WY'])) }
    it { expect(united_states.regions.map(&:country)).to(all(equal(united_states))) }
  end

  describe '#name' do
    it { expect(united_states.name).to(eq('United States of America')) }
    it { expect(described_class.new(alpha2: 'ZZ').name).to(eq('ZZ')) }
  end

  describe '#valid_postal_code?' do
    it { expect(canada.valid_postal_code?('90001')).to(be(false)) }
    it { expect(canada.valid_postal_code?('K1A 0B1')).to(be(true)) }
    it { expect(canada.valid_postal_code?('K1A0B1')).to(be(true)) }
    it { expect(canada.valid_postal_code?('k1a 0b1')).to(be(true)) }
    it { expect(described_class.find('MX').valid_postal_code?('01000')).to(be(true)) }
    it { expect(described_class.find('MX').valid_postal_code?('01000-1')).to(be(false)) }
    it { expect(described_class.new(alpha2: 'ZZ').valid_postal_code?('anything')).to(be(true)) }
    it { expect(united_states.valid_postal_code?('90001 1234')).to(be(true)) }
    it { expect(united_states.valid_postal_code?('90001-1234')).to(be(true)) }
    it { expect(united_states.valid_postal_code?('900011')).to(be(false)) }
    it { expect(united_states.valid_postal_code?('K1A 0B1')).to(be(false)) }
  end

  describe '#valid_street?' do
    it { expect(canada.valid_street?('12-34 Main St')).to(be(true)) }
    it { expect(united_states.valid_street?('1 Main St')).to(be(true)) }
    it { expect(united_states.valid_street?('12-34 Main St')).to(be(false)) }
  end
end
