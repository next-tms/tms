require 'rails_helper'

RSpec.describe(Tools::SearchShipments) do
  subject(:tool_response) { described_class.call(filter:, server_context: { authorizable: }, sort: ['load_id:desc']) }

  let(:authorizable) { create(:root_broker_user) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'shipments') }
  let(:filter) { nil }
  let!(:shipments) { create_list(:shipment, 2) }

  it { is_expected.not_to(be_error) }
  it { expect(data['items'].pluck('loadId')).to(eq(shipments.map(&:load_id).sort.reverse)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'search_shipments')) }

  context 'with a filter' do
    let(:filter) { { load_id_eq: shipments.first.load_id } }

    it { expect(data['items'].pluck('loadId')).to(eq([shipments.first.load_id])) }
    it { expect(data['totalItems']).to(eq(1)) }
  end
end
