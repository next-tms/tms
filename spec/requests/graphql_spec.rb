require 'rails_helper'

RSpec.describe('GraphQL') do
  describe 'POST /graphql' do
    let(:api_key) { create(:api_key) }
    let(:headers) { {} }
    let(:operation_name) { nil }
    let(:json) { response.parsed_body }
    let(:query) { '{ __typename }' }
    let(:user) { nil }

    before do
      sign_in(user) if user
      post('/graphql', headers:, params: { operationName: operation_name, query: })
    end

    context 'without credentials' do
      let(:query) { '{ shipments { nodes { id } } }' }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json).to(eq('error' => 'Not Authorized')) }
    end

    context 'when signed in' do
      let(:user) { create(:customer_user) }

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when signed in without a valid CSRF token' do
      let(:user) { create(:customer_user) }

      around do |example|
        allow_forgery_protection = GraphQLController.allow_forgery_protection
        GraphQLController.allow_forgery_protection = true
        example.run
      ensure
        GraphQLController.allow_forgery_protection = allow_forgery_protection
      end

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'with the GraphiQL introspection query' do
      let(:operation_name) { 'IntrospectionQuery' }
      let(:query) { GraphQL::Introspection::INTROSPECTION_QUERY }
      let(:user) { create(:customer_user) }

      it { expect(json['errors']).to(be_nil) }
      it { expect(json.dig('data', '__schema')).to(be_present) }
    end

    context 'with an introspection query without credentials' do
      let(:operation_name) { 'IntrospectionQuery' }
      let(:query) { GraphQL::Introspection::INTROSPECTION_QUERY }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end

    context 'with a deep query named IntrospectionQuery that selects more than introspection fields' do
      let(:field_type) { "type { #{'ofType { ' * 7}name#{' }' * 7} }" }
      let(:operation_name) { 'IntrospectionQuery' }
      let(:query) { "query IntrospectionQuery { shipmentByLoadId(loadId: 1) { id } __schema { types { fields { #{field_type} } } } }" }
      let(:user) { create(:customer_user) }

      it { expect(json['errors']).to(include(a_hash_including('message' => a_string_including('exceeds max depth')))) }
    end

    context 'with an introspection query that repeats aliased schema selections' do
      let(:query) { "{ #{(1..150).map { |index| "schema#{index}: __schema { types { name } }" }.join(' ')} }" }
      let(:user) { create(:customer_user) }

      it { expect(json['errors']).to(include(a_hash_including('message' => a_string_including('exceeds max complexity')))) }
    end

    context 'with a deep query that spreads a fragment at the root' do
      let(:field_type) { "type { #{'ofType { ' * 7}name#{' }' * 7} }" }
      let(:query) { "query { ...__data } fragment __data on Query { __schema { types { fields { #{field_type} } } } }" }
      let(:user) { create(:customer_user) }

      it { expect(json['errors']).to(include(a_hash_including('message' => a_string_including('exceeds max depth')))) }
    end

    context 'with an API key as a Bearer token' do
      let(:headers) { { 'Authorization' => "Bearer #{api_key.token}" } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(api_key.reload.last_used_at).to(be_present) }
    end

    context 'with an API key in the X-API-Key header' do
      let(:headers) { { 'X-API-Key' => api_key.token } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(api_key.reload.last_used_at).to(be_present) }
    end

    context 'with an expired API key' do
      let(:api_key) { create(:api_key, expires_at: 1.minute.ago) }
      let(:headers) { { 'X-API-Key' => api_key.token } }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json['error']).to(include(api_key.name, 'expired')) }
    end

    context 'with an unknown API key' do
      let(:headers) { { 'Authorization' => 'Bearer tms_unknown' } }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json['error']).to(eq(I18n.t('api_keys.errors.invalid'))) }
    end

    context 'with a broker carrier API key' do
      let(:api_key) { create(:api_key, :broker_carrier) }
      let(:headers) { { 'X-API-Key' => api_key.token } }

      it { is_expected.to(have_http_status(:unauthorized)) }
      it { expect(json['error']).to(eq(I18n.t('api_keys.errors.user_required'))) }
    end

    context 'when the API key user is deactivated' do
      let(:api_key) { create(:api_key, authorizable: create(:customer_user, deactivated: true)) }
      let(:headers) { { 'X-API-Key' => api_key.token } }

      it { is_expected.to(have_http_status(:unauthorized)) }
    end
  end
end
