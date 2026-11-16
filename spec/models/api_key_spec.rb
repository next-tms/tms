require 'rails_helper'

RSpec.describe(APIKey) do
  subject(:api_key) { create(:api_key, ttl: 30.days) }

  describe '.active' do
    let!(:expired_api_key) { create(:api_key, expires_at: 1.day.ago) }

    it { expect(described_class.active).to(include(api_key)) }
    it { expect(described_class.active).not_to(include(expired_api_key)) }
  end

  describe '.authenticate' do
    it { expect(described_class.authenticate(api_key.token)).to(eq(api_key)) }
    it { expect(described_class.authenticate('tms_unknown')).to(be_nil) }
    it { expect(described_class.authenticate(nil)).to(be_nil) }
    it { expect(described_class.authenticate(api_key.token, client_id: api_key.client_id)).to(eq(api_key)) }
    it { expect(described_class.authenticate(api_key.token, client_id: 'unknown')).to(be_nil) }
  end

  describe '.digest' do
    it { expect(described_class.digest('tms_abc')).to(eq(OpenSSL::Digest::SHA256.hexdigest('tms_abc'))) }
  end

  describe '.expired' do
    let!(:expired_api_key) { create(:api_key, expires_at: 1.day.ago) }

    it { expect(described_class.expired).to(include(expired_api_key)) }
    it { expect(described_class.expired).not_to(include(api_key)) }
  end

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(eq(['created_at', 'expires_at', 'last_used_at', 'name', 'token_suffix'])) }
  end

  describe '#access_token' do
    it { expect(described_class.find_signed(api_key.access_token, purpose: :access_token)).to(eq(api_key)) }
    it { expect(described_class.find_signed(api_key.access_token)).to(be_nil) }
  end

  describe '#access_token_ttl' do
    it { expect(api_key.access_token_ttl).to(eq(described_class::ACCESS_TOKEN_TTL)) }

    context 'when the key expires sooner' do
      subject(:api_key) { create(:api_key, expires_at: 1.hour.from_now) }

      it { expect(api_key.access_token_ttl).to(be_within(1.minute).of(1.hour)) }
    end
  end

  describe '#active?' do
    it { is_expected.to(be_active) }
    it { expect(build(:api_key, expires_at: 1.second.ago)).not_to(be_active) }
  end

  describe '#expired?' do
    it { is_expected.not_to(be_expired) }
    it { expect(build(:api_key, expires_at: 1.second.ago)).to(be_expired) }
  end

  describe '#expires_soon?' do
    it { is_expected.not_to(be_expires_soon) }
    it { expect(create(:api_key, ttl: 7.days)).to(be_expires_soon) }
  end

  describe '#roll!' do
    let!(:rolled_api_key) { api_key.roll!(grace_period: 1.day) }

    it { expect(rolled_api_key).to(have_attributes(name: api_key.name, rolled_from: api_key, ttl: 30.days, user: api_key.user)) }

    it { expect(rolled_api_key.token).to(start_with(described_class::TOKEN_PREFIX)) }
    it { expect(api_key.expires_at).to(be_within(1.second).of(1.day.from_now)) }
    it { expect(api_key.rolled_to).to(eq(rolled_api_key)) }
  end

  describe '#roll! without a grace period' do
    before { api_key.roll! }

    it { expect(api_key.reload.expires_at).to(be_within(1.minute).of(described_class::ROLL_GRACE_PERIOD.from_now)) }
  end

  describe '#roll! when the key was already rolled' do
    let!(:rolled_api_key) { api_key.roll! }

    it { expect(api_key.roll!).to(eq(rolled_api_key)) }
    it { expect { api_key.roll! }.not_to(change(described_class, :count)) }
  end

  describe '#use!' do
    it { expect { api_key.use! }.to(change(api_key, :last_used_at).from(nil)) }

    context 'when the key was used less than a minute ago' do
      subject(:api_key) { create(:api_key, last_used_at: 10.seconds.ago) }

      it { expect { api_key.use! }.not_to(change(api_key, :last_used_at)) }
    end
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:rolled_from).class_name('APIKey').optional) }
    it { is_expected.to(belong_to(:user)) }
  end

  describe 'token' do
    it { expect(api_key.client_id).to(match(/\A\h{32}\z/)) }
    it { expect(api_key.token).to(match(/\Atms_[1-9A-HJ-NP-Za-km-z]{43}\z/)) }
    it { expect(api_key.token_digest).to(eq(described_class.digest(api_key.token))) }
    it { expect(api_key.token_suffix).to(eq(api_key.token.last(4))) }
    it { expect(described_class.find(api_key.id).token).to(eq(api_key.token)) }
  end

  describe 'validations' do
    it { expect(api_key.expires_at).to(be_within(1.second).of(30.days.from_now)) }
    it { expect(build(:api_key, ttl: 181.days)).not_to(be_valid) }
    it { expect(build(:api_key, ttl: 0.seconds)).not_to(be_valid) }
    it { expect(build(:api_key, name: '')).not_to(be_valid) }
    it { expect(build(:api_key, ttl: nil)).not_to(be_valid) }
    it { expect(build(:api_key, :carrier)).to(be_valid) }
  end
end
