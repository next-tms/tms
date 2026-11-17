require 'rails_helper'

RSpec.describe(Tools::GetInvoice) do
  subject(:tool_response) { described_class.call(id: receivable.id.to_s, server_context: { authorizable: create(:root_broker_user) }) }

  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'invoice') }
  let(:receivable) { create(:receivable) }

  before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

  it { is_expected.not_to(be_error) }
  it { expect(data['id']).to(eq(receivable.id.to_s)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'get_invoice')) }
end
