require 'rails_helper'

RSpec.describe('GraphQL') do
  describe 'POST /graphql' do
    before { post('/graphql', params: { query: '{ shipments { nodes { id } } }' }) }

    it { is_expected.to(have_http_status(:unauthorized)) }
    it { expect(response.parsed_body).to(eq('error' => 'Not Authorized')) }
  end
end
