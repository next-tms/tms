require 'rails_helper'

RSpec.describe(QuickbooksPolicy) do
  let(:broker) { create(:broker) }
  let(:contact) do
    c = build(:contact).tap do |u|
      u.companyable = broker
    end
    c.save
    c
  end

  let(:user) do
    build(:user, contact:).tap do |u|
      u.companyable = broker
    end
  end

  let(:policy) { described_class.new(user, user:) }

  before do
    create(:intuit_account, broker:)
  end

  describe '#accounts_payable_show?' do
    subject { policy.apply(:accounts_payable_show?) }

    context 'when user is broker, with intuit_account and is accounts_payable' do
      before { contact.contact_roles.create(role: :accounts_payable) }

      it { is_expected.to(be(true)) }
    end

    context 'when user is not accounts_payable' do
      it { is_expected.to(be(false)) }
    end
  end

  describe '#accounts_receivable_show?' do
    subject { policy.apply(:accounts_receivable_show?) }

    context 'when user is broker, with intuit_account and is accounts_receivable' do
      before { contact.contact_roles.create(role: :accounts_receivable) }

      it { is_expected.to(be(true)) }
    end

    context 'when user is not accounts_receivable' do
      it { is_expected.to(be(false)) }
    end
  end

  describe '#root_show?' do
    subject { policy.apply(:root_show?) }

    context 'when user is broker, with intuit_account and has root role' do
      before { contact.contact_roles.create(role: :root) }

      it { is_expected.to(be(true)) }
    end

    context 'when user does not have root role' do
      it { is_expected.to(be(false)) }
    end
  end
end
