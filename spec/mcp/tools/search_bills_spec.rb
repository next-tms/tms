require 'rails_helper'

RSpec.describe(Tools::SearchBills) do
  subject(:tool_response) { described_class.call(page_size: 10, server_context: { authorizable: create(:root_broker_user) }) }

  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'bills') }
  let!(:payment_transaction) { create(:payment_transaction) }

  it { is_expected.not_to(be_error) }
  it { expect(data['items'].pluck('id')).to(include(payment_transaction.id.to_s)) }
  it { expect(data['pageSize']).to(eq(10)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'search_bills')) }
end
