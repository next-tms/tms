require 'rails_helper'

RSpec.describe(InvitationPolicy) do
  let(:broker_customer) { create(:broker_customer) }
  let(:policy) { described_class.new(invitee, authorizable:) }

  describe '#create?' do
    subject { policy.apply(:create?) }

    context 'when inviting staff' do
      let(:invitee) { build(:broker_user) }

      context 'with a root broker' do
        let(:authorizable) { create(:root_broker_user) }

        it { is_expected.to(be(true)) }
      end

      context 'with an accounts payable broker' do
        let(:authorizable) { create(:broker_user).tap { |user| user.add_role(:accounts_payable) } }

        it { is_expected.to(be(false)) }
      end
    end

    context 'when inviting a carrier user' do
      let(:invitee) { build(:carrier_user) }

      context 'with a root customer' do
        let(:authorizable) { create(:customer_user).tap { |user| user.add_role(:root) } }

        it { is_expected.to(be(false)) }
      end

      context 'with an accounts payable broker' do
        let(:authorizable) { create(:broker_user).tap { |user| user.add_role(:accounts_payable) } }

        it { is_expected.to(be(true)) }

        context "with another company's contact" do
          let(:invitee) { build(:carrier_user, contact: create(:contact, companyable: create(:broker_customer))) }

          it { is_expected.to(be(false)) }
        end
      end

      context 'with a carrier user' do
        let(:authorizable) { create(:carrier_user).tap { |user| user.add_role(:accounts_payable) } }

        it { is_expected.to(be(false)) }
      end

      context 'with a dispatch broker' do
        let(:authorizable) { create(:broker_user).tap { |user| user.add_role(:dispatch) } }

        it { is_expected.to(be(false)) }
      end
    end

    context 'when inviting a customer user' do
      let(:authorizable) { create(:broker_user) }
      let(:invitee) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(be(false)) }

      context 'with a sales rep for the customer' do
        before { BrokerCustomerSalesRep.create!(broker_customer:, commission_percent: 5, user: authorizable) }

        it { is_expected.to(be(true)) }
      end
    end
  end
end
