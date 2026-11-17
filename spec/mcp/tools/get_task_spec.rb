require 'rails_helper'

RSpec.describe(Tools::GetTask) do
  subject(:tool_response) { described_class.call(id: problem.id.to_s, server_context: { authorizable: }) }

  let(:authorizable) { create(:root_broker_user) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'task') }
  let(:problem) { create(:problem) }

  it { is_expected.not_to(be_error) }
  it { expect(data['id']).to(eq(problem.id.to_s)) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'get_task')) }
end
