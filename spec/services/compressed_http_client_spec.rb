require 'rails_helper'

RSpec.describe(CompressedHTTPClient) do
  let(:client) { instance_double(described_class, delete: nil, get: nil, patch: nil, post: nil, put: nil) }

  before { allow(described_class).to(receive(:new).and_return(client)) }

  describe '.delete' do
    before { described_class.delete('https://example.com', headers: { 'X-Test' => '1' }, h2c: true) }

    it { expect(described_class).to(have_received(:new).with(described_class::ACCEPT, persistent: false, h2c: true)) }
    it { expect(client).to(have_received(:delete).with('https://example.com', headers: { 'X-Test' => '1' })) }
  end

  describe '.filter_uri' do
    subject { described_class.filter_uri(uri) }

    let(:uri) { 'https://example.com/lookup?auth-id=id&auth-token=token&key=secret&zipcode=97701' }

    it { is_expected.to(eq('https://example.com/lookup?auth-id=%5BFILTERED%5D&auth-token=%5BFILTERED%5D&key=%5BFILTERED%5D&zipcode=97701')) }

    context 'without a query' do
      let(:uri) { 'https://example.com/lookup' }

      it { is_expected.to(eq('https://example.com/lookup')) }
    end
  end

  describe '.get' do
    before { described_class.get('https://example.com', accept: 'text/csv') }

    it { expect(described_class).to(have_received(:new).with('text/csv', persistent: false)) }
    it { expect(client).to(have_received(:get).with('https://example.com')) }
  end

  describe '.patch' do
    before { described_class.patch('https://example.com', json: { name: 'Acme' }, content_type: 'text/json') }

    it { expect(described_class).to(have_received(:new).with(described_class::ACCEPT, persistent: false, content_type: 'text/json')) }
    it { expect(client).to(have_received(:patch).with('https://example.com', json: { name: 'Acme' })) }
  end

  describe '.post' do
    before { described_class.post('https://example.com', body: 'payload', headers: { 'X-Test' => '1' }) }

    it { expect(described_class).to(have_received(:new).with(described_class::ACCEPT, persistent: false)) }
    it { expect(client).to(have_received(:post).with('https://example.com', body: 'payload', headers: { 'X-Test' => '1' })) }
  end

  describe '.put' do
    before { described_class.put('https://example.com', json: { name: 'Acme' }) }

    it { expect(described_class).to(have_received(:new).with(described_class::ACCEPT, persistent: false)) }
    it { expect(client).to(have_received(:put).with('https://example.com', json: { name: 'Acme' })) }
  end
end
