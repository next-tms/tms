require 'rails_helper'

RSpec.describe(Resolvers::ShipmentsResolver) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:arguments) { {} }
  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, scac: 'ABCD')) }
  let(:items) { result.dig('data', 'shipments', 'items') }
  let(:load_ids) { items.pluck('loadId') }
  let(:other_broker_carrier) { create(:broker_carrier, carrier: create(:carrier, scac: 'WXYZ')) }

  let(:query) do
    <<~GRAPHQL
      query($filter: ShipmentFilter, $page: Int, $pageSize: Int, $sort: [String!]) {
        shipments(filter: $filter, page: $page, pageSize: $pageSize, sort: $sort) {
          items { loadId }
          page
          pageSize
          pages
          totalItems
          updatedAt
          version
        }
      }
    GRAPHQL
  end

  let!(:shipments) do
    [
      create(:shipment, broker_carrier:, load_id: 1001, shipper_name: 'Acme'),
      create(:shipment, broker_carrier:, load_id: 1002, shipper_name: 'Globex'),
      create(:shipment, broker_carrier: other_broker_carrier, load_id: 1003, shipper_name: 'Initech')
    ]
  end

  let(:variables) { arguments }

  it_behaves_like('filterable GraphQL resolver')

  describe '#resolve' do
    it { expect(load_ids).to(eq([1001, 1002, 1003])) }
    it { expect(result.dig('data', 'shipments')).to(include('page' => 1, 'pageSize' => 20, 'pages' => 1, 'totalItems' => 3)) }
    it { expect(Time.zone.parse(result.dig('data', 'shipments', 'updatedAt'))).to(be_within(1.second).of(shipments.map(&:updated_at).max)) }

    context 'when the user is a carrier' do
      let(:authorizable) { create(:user, companyable: other_broker_carrier) }

      it { expect(load_ids).to(eq([1003])) }
    end

    context 'when the user may only see some records' do
      let(:authorizable) { create(:customer_user, companyable: shipments.first.broker_customer) }

      it { expect(load_ids).to(eq([1001])) }
    end

    context 'with a filter' do
      let(:arguments) { { filter: { shipperNameCont: 'glob' } } }

      it { expect(load_ids).to(eq([1002])) }
    end

    context 'with a page past the last page' do
      let(:arguments) { { page: 5 } }

      it { expect(result['errors'].first['extensions']).to(eq('code' => 'PAGE_OVERFLOW')) }
    end

    context 'with a pageSize above the maximum' do
      let(:arguments) { { pageSize: 1_000 } }

      it { expect(result.dig('data', 'shipments', 'pageSize')).to(eq(100)) }
    end

    context 'with a sort' do
      let(:arguments) { { sort: ['shipper_name:desc'] } }

      it { expect(load_ids).to(eq([1003, 1002, 1001])) }
    end

    context 'with an association filter' do
      let(:arguments) { { filter: { brokerCarrierCarrierScacEq: 'WXYZ' } } }

      it { expect(load_ids).to(eq([1003])) }
    end

    context 'with an association sort' do
      let(:arguments) { { sort: ['broker_carrier_carrier_scac:desc', 'shipper_name'] } }

      it { expect(load_ids).to(eq([1003, 1001, 1002])) }
    end

    context 'with an id filter' do
      let(:arguments) { { filter: { brokerCarrierIdEq: other_broker_carrier.id } } }

      it { expect(load_ids).to(eq([1003])) }
    end

    context 'with blank OR filter conditions' do
      let(:arguments) { { filter: { or: [{ shipperNameEq: nil }] } } }

      it { expect(load_ids).to(eq([1001, 1002, 1003])) }
    end

    context 'with OR and base filters combined' do
      let(:arguments) do
        { filter: { brokerCarrierCarrierScacEq: 'ABCD', or: [{ shipperNameEq: 'Globex' }, { shipperNameEq: 'Initech' }] } }
      end

      it { expect(load_ids).to(eq([1002])) }
    end

    context 'with OR filter conditions' do
      let(:arguments) { { filter: { or: [{ brokerCarrierCarrierScacEq: 'WXYZ' }, { shipperNameEq: 'Acme' }] } } }

      it { expect(load_ids).to(eq([1001, 1003])) }
    end

    context 'with an exact load id filter' do
      let(:arguments) { { filter: { loadIdEq: 1002 } } }

      it { expect(load_ids).to(eq([1002])) }
    end

    context 'with a page below one' do
      let(:arguments) { { page: 0 } }

      it { expect(result['errors']).to(include(a_hash_including('message' => a_string_including('page')))) }
      it { expect(result['data']).to(be_nil) }
    end

    context 'with nested OR filter conditions' do
      let(:arguments) { { filter: { or: [{ or: [{ shipperNameEq: 'Acme' }, { shipperNameEq: 'Initech' }] }] } } }

      it { expect(load_ids).to(eq([1001, 1003])) }
    end

    context "when a customer ORs another customer's id" do
      let(:arguments) { { filter: { or: [{ brokerCustomerIdEq: shipments.last.broker_customer_id }] } } }
      let(:authorizable) { create(:customer_user, companyable: shipments.first.broker_customer) }

      it { expect(load_ids).to(be_empty) }
    end

    context "when a carrier ORs another carrier's id" do
      let(:arguments) { { filter: { or: [{ brokerCarrierIdEq: broker_carrier.id }] } } }
      let(:authorizable) { create(:user, companyable: other_broker_carrier) }

      it { expect(load_ids).to(be_empty) }
    end

    context 'with a null pageSize' do
      let(:query) { '{ shipments(pageSize: null) { pageSize } }' }

      it { expect(result['errors']).to(include(a_hash_including('message' => a_string_including('pageSize')))) }
    end

    context 'with page and pageSize' do
      let(:arguments) { { page: 2, pageSize: 2 } }
      let(:first_page) { LiftoffSchema.execute(query, context: { authorizable: }, variables: { page: 1, pageSize: 2 }).to_h }
      let(:first_page_fingerprint) { first_page.dig('data', 'shipments').slice('updatedAt', 'version') }
      let(:fingerprint) { result.dig('data', 'shipments').slice('updatedAt', 'version') }

      it { expect(load_ids).to(eq([1003])) }
      it { expect(fingerprint).to(eq(first_page_fingerprint)) }
      it { expect(fingerprint['version']).to(eq(Shipment.all.cache_version)) }
      it { expect(result.dig('data', 'shipments')).to(include('page' => 2, 'pageSize' => 2, 'pages' => 2, 'totalItems' => 3)) }

      it do
        version = fingerprint['version']
        shipments.first.destroy!

        expect(first_page_fingerprint['version']).not_to(eq(version))
      end
    end

    context 'with nested collections whose page sizes multiply past the complexity limit' do
      let(:query) do
        <<~GRAPHQL
          {
            shipments(pageSize: 100) {
              items { brokerCustomer { shipments(pageSize: 100) { items { brokerCustomer { shipments(pageSize: 100) { items { id } } } } } } }
            }
          }
        GRAPHQL
      end

      it { expect(result['errors']).to(include(a_hash_including('message' => a_string_including('exceeds max complexity')))) }
    end
  end

  describe '.page_limit' do
    it { expect(described_class.page_limit(20)).to(eq(20)) }
    it { expect(described_class.page_limit(0)).to(eq(1)) }
    it { expect(described_class.page_limit(1_000)).to(eq(100)) }
  end
end
