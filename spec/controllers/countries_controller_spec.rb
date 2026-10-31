require 'rails_helper'

RSpec.describe(CountriesController) do
  render_views

  let(:json) { response.parsed_body }

  before { sign_in(create(:root_broker_user)) }

  describe 'GET #show' do
    before { get(:show, format: :json, params: { id: 'US' }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.dig('country', 'id')).to(eq('US')) }
    it { expect(json.dig('country', 'name')).to(eq('United States of America')) }
    it { expect(json.dig('country', 'regions').pluck('id')).to(eq(['US-CA', 'US-TX', 'US-WY'])) }
    it { expect(json.dig('country', 'regions').first).to(eq({ 'abbreviation' => 'CA', 'id' => 'US-CA', 'name' => 'California' })) }
    it { expect(response.headers['Cache-Control']).to(include('public', 'max-age=86400')) }
    it { expect(response.headers['ETag']).to(be_present) }

    context 'when the ETag matches' do
      before do
        request.headers['If-None-Match'] = response.headers['ETag']
        get(:show, format: :json, params: { id: 'US' })
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when only a region abbreviation changed since the ETag' do
      before do
        request.headers['If-None-Match'] = response.headers['ETag']

        original_hash = JSON.parse(TransponderCountries::FIXTURE_PATH.read)
        original_hash.dig('data', 'fetchCountries').last['regions'].first['abbreviation'] = 'CF'
        stub_transponder_countries(original_hash)

        get(:show, format: :json, params: { id: 'US' })
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(json.dig('country', 'regions').pluck('abbreviation')).to(eq(['CF', 'TX', 'WY'])) }
    end
  end

  describe 'GET #show with an unknown country' do
    it { expect { get(:show, format: :json, params: { id: 'ZZ' }) }.to(raise_error(ActiveRecord::RecordNotFound)) }
  end
end
