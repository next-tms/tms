require 'rails_helper'

RSpec.describe(GraphQLClient::Transponder) do
  describe '.uri' do
    subject(:uri) { described_class.uri.to_s }

    before { stub_const('ENV', ENV.to_h.merge('TRANSPONDER_URL' => url).compact) }

    context 'when TRANSPONDER_URL is missing' do
      let(:url) { nil }

      it { expect { uri }.to(raise_error(KeyError)) }
    end

    context 'when TRANSPONDER_URL is set' do
      let(:url) { 'http://transponder.example.com/graphql' }

      it { is_expected.to(eq('http://transponder.example.com/graphql')) }
    end
  end

  describe 'HTTPAdapter' do
    describe 'TIMEOUT' do
      it { expect(described_class::HTTPAdapter::TIMEOUT).to(eq(connect_timeout: 5, total_request_timeout: 150)) }
    end

    describe '#execute' do
      subject(:error) do
        described_class::HTTPAdapter.new(url).execute(document: GraphQL.parse('query FetchRates { fetchRates { id } }'))
      rescue GraphQL::Client::Error => e
        e
      end

      let!(:requests) { Concurrent::AtomicFixnum.new }
      let!(:server) { TCPServer.new('localhost', 0) }
      let!(:thread) do
        Thread.new do
          loop do
            socket = server.accept
            socket.gets("\r\n\r\n")
            requests.increment
            sleep(1)
            socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n{}")
          rescue IOError, SystemCallError
            next
          ensure
            socket&.close
          end
        end
      end

      let(:url) { "http://localhost:#{server.addr[1]}/graphql" }

      before do
        stub_const("#{described_class}::HTTPAdapter::TIMEOUT", { connect_timeout: 1, total_request_timeout: 0.3 })
        allow(described_class).to(receive(:endpoint).and_return(url))
        error
      end

      after do
        thread.kill
        server.close
      end

      it { expect(error).to(be_a(GraphQL::Client::Error)) }
      it { expect(requests.value).to(eq(1)) }
    end
  end
end
