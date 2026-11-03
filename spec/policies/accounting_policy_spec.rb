require 'rails_helper'

RSpec.describe(AccountingPolicy) do
  subject(:policy) { described_class.new(authorizable, authorizable:) }

  let(:authorizable) { create(:broker_user) }

  def grant(role)
    authorizable.contact.contact_roles.create!(role:)
    authorizable.reload
  end

  describe '#accounts_payable_show?' do
    it { expect(policy.accounts_payable_show?).to(be(false)) }

    it 'allows an accounts_payable user' do
      grant(:accounts_payable)
      expect(policy.accounts_payable_show?).to(be(true))
    end

    it 'allows a root user' do
      grant(:root)
      expect(policy.accounts_payable_show?).to(be(true))
    end
  end

  describe '#accounts_receivable_show?' do
    it { expect(policy.accounts_receivable_show?).to(be(false)) }

    it 'allows an accounts_receivable user' do
      grant(:accounts_receivable)
      expect(policy.accounts_receivable_show?).to(be(true))
    end

    it 'allows a root user' do
      grant(:root)
      expect(policy.accounts_receivable_show?).to(be(true))
    end
  end

  describe '#root_show?' do
    it { expect(policy.root_show?).to(be(false)) }

    it 'allows a root user' do
      grant(:root)
      expect(policy.root_show?).to(be(true))
    end

    it 'denies an accounts_payable user' do
      grant(:accounts_payable)
      expect(policy.root_show?).to(be(false))
    end
  end
end
