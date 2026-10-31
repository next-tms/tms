require 'rails_helper'

RSpec.describe Accounting::Wave::Product do
  let!(:integration) { create(:integration, :wave, credentials:) }

  describe '.id' do
    subject(:id) { described_class.id }

    context 'when a product id is already configured' do
      let(:credentials) { { access_token: 'access', business_id: 'biz', product_id: 'configured' } }

      it { is_expected.to eq('configured') }
    end

    context 'when a matching product exists' do
      let(:credentials) { { access_token: 'access', business_id: 'biz' } }

      before { stub_wave('products_freight', query: 'products(') }

      it { is_expected.to eq('prod-freight') }

      context 'when caching the resolved id' do
        before { id }

        it { expect(integration.reload.credentials['product_id']).to eq('prod-freight') }
      end
    end

    context 'when no product exists' do
      let(:credentials) { { access_token: 'access', business_id: 'biz' } }

      before do
        stub_wave('products_empty', query: 'products(')
        stub_wave('income_accounts', query: 'accounts(')
        stub_wave('product_create', query: 'productCreate')
      end

      it { is_expected.to eq('prod-new') }

      context 'when sending the mutation' do
        before { id }

        it do
          expect(WebMock).to(have_requested(:post, Accounting::Wave::Service::GRAPHQL_URL).with do |request|
            body = JSON.parse(request.body)
            body['query'].include?('productCreate') && body.dig('variables', 'input', 'incomeAccountId') == 'acct-income'
          end)
        end
      end
    end
  end
end
