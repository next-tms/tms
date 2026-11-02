require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Service do
  let(:credentials) { attributes_for(:integration)[:credentials] }
  let(:integration) { create(:integration, credentials:) }
  let(:service) { described_class.new(integration) }

  describe '#connected?' do
    it { expect(service).to be_connected }

    context 'when the refresh token is blank' do
      let(:integration) { build(:integration, credentials: credentials.merge(refresh_token: nil)) }

      it { expect(service).not_to be_connected }
    end

    context 'when the refresh token is revoked' do
      let(:integration) { create(:integration, credentials: credentials.merge(refresh_token_revoked_at: Time.current)) }

      it { expect(service).not_to be_connected }
    end
  end

  describe '#perform_authenticated_request' do
    let(:attempts) { [] }
    let(:refreshed) { OAuth2::AccessToken.new(nil, 'new-access', expires_at: 1.hour.from_now.to_i, refresh_token: 'new-refresh') }

    let(:result) do
      service.perform_authenticated_request do |access_token|
        attempts << access_token.token
        raise OAuth2::Error, { 'error' => 'invalid_token' } if attempts.one?

        access_token.token
      end
    end

    before do
      allow(service).to receive(:sleep)
      allow_any_instance_of(OAuth2::AccessToken).to receive(:refresh!).and_return(refreshed) # rubocop:disable RSpec/AnyInstance
    end

    it { expect(result).to eq('new-access') }
    it { expect { result }.to change { integration.reload.credentials['refresh_token'] }.to('new-refresh') }

    context 'when another job already rotated the refresh token' do
      let(:result) do
        service.perform_authenticated_request do |access_token|
          attempts << access_token.token

          if attempts.one?
            Integration.find(integration.id).update!(credentials: credentials.merge(access_token: 'other-access', refresh_token: 'other-refresh'))
            raise OAuth2::Error, { 'error' => 'invalid_token' }
          end

          access_token.token
        end
      end

      it { expect(result).to eq('other-access') }
      it { expect { result }.to change { integration.reload.credentials['refresh_token'] }.to('other-refresh') }
    end

    context 'when every attempt fails' do
      let(:result) { service.perform_authenticated_request { raise OAuth2::Error, { 'error' => 'invalid_token' } } }

      it { expect { result }.to raise_error(described_class::ExceededAuthAttempts) }
    end

    context 'when refreshing fails for another reason' do
      before do
        allow_any_instance_of(OAuth2::AccessToken).to receive(:refresh!).and_raise(OAuth2::Error, { 'error' => 'invalid_client' }) # rubocop:disable RSpec/AnyInstance
      end

      it { expect { result }.to raise_error(OAuth2::Error) }

      it 'keeps the integration connected' do
        expect { result }.to raise_error(OAuth2::Error)
        expect(integration.reload.service).to be_connected
      end
    end

    context 'when the refresh token is invalid' do
      before do
        allow_any_instance_of(OAuth2::AccessToken).to receive(:refresh!).and_raise(OAuth2::Error, { 'error' => 'invalid_grant' }) # rubocop:disable RSpec/AnyInstance
      end

      it { expect { result }.to raise_error(described_class::Disconnected) }

      it 'marks the integration as disconnected' do
        expect { result }.to raise_error(described_class::Disconnected)
        expect(Integration.find(integration.id).service).not_to be_connected
      end
    end
  end
end
