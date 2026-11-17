require 'rails_helper'

RSpec.describe(Tools::GetCarrier) do
  subject(:tool_response) { described_class.call(id: carrier.id.to_s, server_context: { authorizable: create(:root_broker_user) }) }

  let(:carrier) { create(:carrier) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'carrier') }

  it { is_expected.not_to(be_error) }
  it { expect(data['id']).to(eq(carrier.id.to_s)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'get_carrier')) }
end
