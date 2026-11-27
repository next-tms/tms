require 'rails_helper'

RSpec.describe(Transponder::ORM::Carrier) do
  let(:custom) { described_class.new(id: 'custom') }
  let(:saia) { described_class.find_by(scac: 'SAIA') }
  let(:tql) { described_class.find_by(scac: 'TQYL') }

  describe '.all' do
    it { expect(described_class.pluck(:scac)).to(eq(['SAIA', 'TQYL'])) }
    it { expect(described_class.all).to(equal(described_class.all)) }

    context 'when the collection is older than MEMO_EXPIRES_IN' do
      let!(:collection) { described_class.all }

      before { Timecop.travel(described_class::MEMO_EXPIRES_IN.from_now + 1.second) }
      after { Timecop.return }

      it { expect(described_class.all).not_to(equal(collection)) }
      it { expect(described_class.all).to(equal(described_class.all)) }
    end

    context 'when Transponder is disabled' do
      before do
        allow(GraphQLClient::Transponder).to(receive(:enabled?).and_return(false))
        described_class.reset
        described_class.all
      end

      it { expect(described_class.all.to_a).to(eq([])) }
      it { expect(GraphQLClient::Transponder::Client).not_to(have_received(:query)) }
    end

    context 'when Transponder returns errors' do
      before { stub_transponder_carriers({ 'errors' => [{ 'message' => 'Boom' }] }) }

      it { expect { described_class.all }.to(raise_error(GraphQL::Client::Error, 'Boom')) }
    end
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:id)) }
  end

  describe '#initialize' do
    it { expect(saia).to(have_attributes(legal_name: 'Saia Motor Freight Line, LLC', us_mc_number: '92726')) }
    it { expect(saia.required_credential_types).to(eq(%i[api])) }
    it { expect(saia.valid_tracking_number_pattern).to(eq(/\A\d{11}\z/)) }
    it { expect(tql.valid_tracking_number_pattern).to(be_nil) }
    it { expect(custom.required_credential_types).to(eq([])) }
    it { expect(saia).to(have_attributes(us_dot_number: '29124', website_url: 'https://www.saia.com')) }
    it { expect(saia.check_mailing_addresses.map(&:city)).to(eq(['Dallas'])) }
    it { expect(saia.contacts.map(&:department)).to(eq(['Dispatch'])) }
    it { expect(saia.headquarters.city).to(eq('Johns Creek')) }
    it { expect(saia.lanes.map(&:carrier)).to(eq([saia, saia])) }
    it { expect(saia.terminals.map(&:carrier)).to(eq([saia])) }
    it { expect(saia.territories).to(eq([])) }
    it { expect(tql.lanes).to(eq([])) }
    it { expect(tql.territories.map(&:to_s)).to(eq(['CA, US', 'NV, US (889, 890, 891)'])) }
    it { expect(tql.headquarters).to(be_nil) }
    it { expect(tql.website_url).to(be_nil) }
  end

  describe '#acts_as_broker?' do
    it { expect(saia.acts_as_broker?).to(be(false)) }
    it { expect(tql.acts_as_broker?).to(be(true)) }
  end

  describe '#addresses' do
    it { expect(saia.addresses.map(&:city)).to(eq(['Johns Creek', 'Dallas', 'Austin'])) }
    it { expect(tql.addresses).to(eq([])) }
  end

  describe '#api?' do
    it { expect(saia.api?).to(be(true)) }
    it { expect(custom.api?).to(be(false)) }
  end

  describe '#bol_requires_tracking_number?' do
    it { expect(saia.bol_requires_tracking_number?).to(be(true)) }
    it { expect(custom.bol_requires_tracking_number?).to(be(false)) }
  end

  describe '#consider_bol_and_pod_documents_same?' do
    it { expect(saia.consider_bol_and_pod_documents_same?).to(be(false)) }
    it { expect(tql.consider_bol_and_pod_documents_same?).to(be(true)) }
  end

  describe '#create_pickup_implemented?' do
    it { expect(saia.create_pickup_implemented?).to(be(true)) }
    it { expect(custom.create_pickup_implemented?).to(be(false)) }
  end

  describe '#find_rates_implemented?' do
    it { expect(saia.find_rates_implemented?).to(be(true)) }
    it { expect(custom.find_rates_implemented?).to(be(false)) }
  end

  describe '#find_rates_with_declared_value?' do
    it { expect(saia.find_rates_with_declared_value?).to(be(false)) }
    it { expect(tql.find_rates_with_declared_value?).to(be(true)) }
  end

  describe '#matching_lanes' do
    subject(:matching_lanes) { saia.matching_lanes(destination:, origin:) }

    let(:destination) { build(:address, region_iso31662: 'US-TX') }
    let(:origin) { build(:address, region_iso31662: 'US-CA') }
    let(:variables) do
      { destination: destination.to_transponder_graphql_input, id: saia.id, origin: origin.to_transponder_graphql_input }
    end

    before { stub_transponder_matching_lanes('7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02', 'removed', '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01') }

    it { expect(matching_lanes.map(&:id)).to(eq(['7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02', '3f6d9a52-1c0e-4d8b-9a7e-5b2c4d6e8f01'])) }

    context 'when the lanes are fetched' do
      let(:query) { GraphQLClient::Transponder::Query::FetchMatchingLanes::DETAILS }

      before { matching_lanes }

      it { expect(GraphQLClient::Transponder::Client).to(have_received(:query).with(query, variables:)) }
    end

    context 'when Transponder returns errors' do
      before { stub_transponder_matching_lanes(errors: [{ 'message' => 'Boom' }]) }

      it { expect { matching_lanes }.to(raise_error(GraphQL::Client::Error, 'Boom')) }
    end
  end

  describe '#name' do
    it { expect(saia.name).to(eq('Saia')) }
    it { expect(custom.name).to(eq('custom')) }
  end

  describe '#pickup_number_is_tracking_number?' do
    it { expect(saia.pickup_number_is_tracking_number?).to(be(false)) }
    it { expect(tql.pickup_number_is_tracking_number?).to(be(true)) }
  end

  describe '#rates_with_excessive_length_fees?' do
    it { expect(saia.rates_with_excessive_length_fees?).to(be(true)) }
    it { expect(tql.rates_with_excessive_length_fees?).to(be(false)) }
  end

  describe '#serve?' do
    subject(:serve) { tql.serve?(destination:, origin:) }

    let(:destination) { build(:address, region_iso31662: 'US-NV') }
    let(:origin) { build(:address, region_iso31662: 'US-CA') }
    let(:variables) do
      { destination: destination.to_transponder_graphql_input, id: tql.id, origin: origin.to_transponder_graphql_input }
    end

    before { stub_transponder_serve(true) }

    it { is_expected.to(be(true)) }

    context 'when the carrier does not serve the points' do
      before { stub_transponder_serve(false) }

      it { is_expected.to(be(false)) }
    end

    context 'when the coverage is fetched' do
      let(:query) { GraphQLClient::Transponder::Query::FetchServe::DETAILS }

      before { serve }

      it { expect(GraphQLClient::Transponder::Client).to(have_received(:query).with(query, variables:)) }
    end

    context 'when Transponder returns errors' do
      before { stub_transponder_serve(nil, errors: [{ 'message' => 'Boom' }]) }

      it { expect { serve }.to(raise_error(GraphQL::Client::Error, 'Boom')) }
    end
  end

  describe '#valid_tracking_number?' do
    it { expect(saia.valid_tracking_number?('12345678901')).to(be(true)) }
    it { expect(saia.valid_tracking_number?('1234')).to(be(false)) }
    it { expect(saia.valid_tracking_number?(nil)).to(be(false)) }
    it { expect(tql.valid_tracking_number?('anything')).to(be(true)) }
  end
end
