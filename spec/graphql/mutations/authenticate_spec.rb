require 'rails_helper'

RSpec.describe(Mutations::Authenticate) do
  describe '#resolve' do
    subject(:result) { described_class.new(object: nil, field: nil, context: { session: {} }).resolve(**arguments) }

    let(:arguments) { { credentials: { email: user.email, password: user.password } } }
    let(:user) { create(:broker_user) }

    it { expect(result[:token]).to(be_present) }
    it { expect(result[:user]).to(eq(user)) }

    context 'without credentials' do
      let(:arguments) { {} }

      it { is_expected.to(be_nil) }
    end

    context 'with an unknown email' do
      let(:arguments) { { credentials: { email: 'wrong', password: user.password } } }

      it { is_expected.to(be_nil) }
    end

    context 'with a wrong password' do
      let(:arguments) { { credentials: { email: user.email, password: 'wrong' } } }

      it { is_expected.to(be_nil) }
    end
  end
end
