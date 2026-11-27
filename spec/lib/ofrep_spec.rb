require 'rails_helper'

RSpec.describe(OFREP) do
  let(:api_key) { 'secret' }
  let(:endpoint) { 'https://flags.example.com/api/' }
  let(:url) { 'https://flags.example.com/api/ofrep/v1/evaluate/flags/operator_notice' }

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('OFREP_API_KEY').and_return(api_key))
    allow(ENV).to(receive(:fetch).with('OFREP_API_KEY', nil).and_return(api_key))
    allow(ENV).to(receive(:fetch).with('OFREP_ENDPOINT', nil).and_return(endpoint))
  end

  describe '.configured?' do
    it { is_expected.to(be_configured) }

    context 'without an endpoint' do
      let(:endpoint) { nil }

      it { is_expected.not_to(be_configured) }
    end
  end

  describe '.evaluate' do
    subject(:evaluate) { described_class.evaluate('operator_notice') }

    let(:body) do
      { key: 'operator_notice', reason: 'TARGETING_MATCH', value: { message: 'Hi', status: 'past_due' }, variant: 'past_due' }.to_json
    end
    let(:status) { 200 }

    before do
      stub_request(:post, url).with(body: { context: {} }).to_return(body:, headers: { 'Content-Type' => 'application/json' }, status:)
    end

    it { is_expected.to(eq('message' => 'Hi', 'status' => 'past_due')) }

    it do
      evaluate
      expect(a_request(:post, url).with(headers: { 'Authorization' => 'Bearer secret' })).to(have_been_made)
    end

    context 'when the flag is disabled' do
      let(:body) { { key: 'operator_notice', reason: 'DISABLED', value: {} }.to_json }

      it { is_expected.to(be_nil) }
    end

    context 'when the flag is not found' do
      let(:body) { { errorCode: 'FLAG_NOT_FOUND', key: 'operator_notice' }.to_json }
      let(:status) { 404 }

      it { is_expected.to(be_nil) }
    end

    context 'when the path is not found' do
      let(:body) { {}.to_json }
      let(:status) { 404 }

      it { expect { evaluate }.to(raise_error(OFREP::Error)) }
    end

    context 'when the request times out' do
      before { stub_request(:post, url).to_timeout }

      it { expect { evaluate }.to(raise_error(OFREP::Error)) }
    end

    context 'when the response is not an object' do
      let(:body) { 'oops'.to_json }

      it { expect { evaluate }.to(raise_error(OFREP::Error)) }
    end

    context 'when the response is not JSON' do
      let(:body) { 'oops' }

      it { expect { evaluate }.to(raise_error(OFREP::Error)) }
    end

    context 'when the response has no value' do
      let(:body) { { key: 'operator_notice', reason: 'TARGETING_MATCH' }.to_json }

      it { expect { evaluate }.to(raise_error(OFREP::Error)) }
    end

    context 'when unauthorized' do
      let(:body) { {}.to_json }
      let(:status) { 401 }

      it { expect { evaluate }.to(raise_error(OFREP::Error)) }
    end

    context 'without an API key' do
      let(:api_key) { nil }

      it do
        evaluate
        expect(a_request(:post, url).with { |request| !request.headers.key?('Authorization') }).to(have_been_made)
      end
    end
  end
end
