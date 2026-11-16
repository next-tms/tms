require 'rails_helper'

RSpec.describe('API catalog') do
  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  describe 'GET /.well-known/api-catalog' do
    before { get('/.well-known/api-catalog') }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.content_type).to(start_with('application/linkset+json; profile="https://www.rfc-editor.org/info/rfc9727"')) }
    it { expect(response.headers['Link']).to(eq('<http://www.example.com/.well-known/api-catalog>; rel="api-catalog"')) }
    it { expect(response.headers['Cache-Control']).to(include('public')) }

    it do
      expect(json[:linkset].pluck(:anchor)).to(
        eq(['http://www.example.com/api/v1', 'http://www.example.com/api/dsdc', 'http://www.example.com/graphql'])
      )
    end

    it { expect(json[:linkset].first[:'service-doc'].sole).to(eq(href: 'https://documenter.getpostman.com/view/1985869/TWDWJch4', type: 'text/html')) }
  end

  describe 'HEAD /.well-known/api-catalog' do
    before { head('/.well-known/api-catalog') }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.headers['Link']).to(include('rel="api-catalog"')) }
  end
end
