require 'rails_helper'

RSpec.describe(Tools::GetCustomer) do
  subject(:tool_response) { described_class.call(id: broker_customer.id.to_s, server_context: { authorizable: create(:root_broker_user) }) }

  let(:broker_customer) { create(:broker_customer) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'customer') }

  it { is_expected.not_to(be_error) }
  it { expect(data['id']).to(eq(broker_customer.id.to_s)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'get_customer')) }
end
