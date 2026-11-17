require 'rails_helper'

RSpec.describe(Tools::GetBill) do
  subject(:tool_response) { described_class.call(id: payment_transaction.id.to_s, server_context: { authorizable: }) }

  let(:authorizable) { create(:root_broker_user) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'bill') }
  let(:payment_transaction) { create(:payment_transaction) }

  it { is_expected.not_to(be_error) }
  it { expect(data['id']).to(eq(payment_transaction.id.to_s)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'get_bill')) }
end
