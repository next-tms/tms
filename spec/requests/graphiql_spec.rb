require 'rails_helper'

RSpec.describe('GraphiQL') do
  describe 'GET /graphiql' do
    context 'when signed in' do
      before do
        sign_in(create(:customer_user))
        get('/graphiql')
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include('GraphiQL.createFetcher', 'csrf-token')) }
    end

    context 'when signed out' do
      before { get('/graphiql') }

      it { is_expected.to(redirect_to('/users/sign_in')) }
    end
  end
end
