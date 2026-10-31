require 'rails_helper'

RSpec.describe(JWTManagerService) do
  describe '.decode' do
    subject(:result) { described_class.decode(jwt:) }

    context 'with a valid token' do
      let(:jwt) { described_class.encode(payload: { 'user_id' => 1 }).jwt }

      it { expect(result.error_message).to(be_nil) }
      it { expect(result.payload).to(eq('user_id' => 1)) }
    end

    context 'with an expired token' do
      let(:jwt) { described_class.encode(payload: { 'exp' => 1.minute.ago.to_i }).jwt }

      it { expect(result.error_message).to(eq(described_class::JWT_EXPIRED_ERROR)) }
      it { expect(result.payload).to(be_nil) }
    end

    context 'with a malformed token' do
      let(:jwt) { 'malformed' }

      it { expect(result.error_message).to(eq(described_class::JWT_DECODE_ERROR)) }
      it { expect(result.payload).to(be_nil) }
    end
  end

  describe '.encode' do
    subject(:result) { described_class.encode(payload: { 'user_id' => 1 }) }

    it { expect(result.error_message).to(be_nil) }
    it { expect(result.jwt).to(be_a(String)) }
  end
end
