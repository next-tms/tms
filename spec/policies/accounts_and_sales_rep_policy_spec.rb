require 'rails_helper'

RSpec.describe(AccountsAndSalesRepPolicy) do
  let(:contact) { create(:contact, companyable: nil) }
  let(:user) { build(:broker_user, contact:) }

  let(:shipment) { build(:shipment) }

  let(:policy) { described_class.new(shipment, user:) }

  describe '#accounts_receivable_show?' do
    subject { policy.apply(:accounts_receivable_show?) }

    context 'when user role is either root and accounts_receivable' do
      before do
        contact.contact_roles.create(role: :accounts_receivable)
        contact.contact_roles.create(role: :root)
      end

      it { is_expected.to(be(true)) }
    end

    context 'when user role is sales rep for record' do
      before { allow(user).to(receive(:sales_rep_for?).with(shipment).and_return(true)) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#accounts_receivable_and_sales_rep_for_all_show?' do
    subject { policy.apply(:accounts_receivable_and_sales_rep_for_all_show?) }

    context 'when user role is accounts_receivable, sales_rep_for_all_broker_customers and sales_rep for record' do
      before do
        contact.contact_roles.create(role: :accounts_receivable)
        contact.contact_roles.create(role: :sales_rep_for_all_broker_customers)
        allow(user).to(receive(:sales_rep_for?).with(shipment).and_return(true))
      end

      it { is_expected.to(be(true)) }
    end
  end
end
