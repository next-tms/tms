require 'rails_helper'

RSpec.describe(ReceivablePolicy) do
  let(:authorizable) { create(:customer_user, companyable: receivable.shipment.broker_customer) }
  let(:policy) { described_class.new(receivable, authorizable:) }
  let(:receivable) { create(:receivable) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Receivable.all, type: :active_record_relation) }

    let!(:other_receivable) { create(:receivable) }

    it { is_expected.to(contain_exactly(receivable)) }

    context 'with a broker user' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(be_empty) }
    end

    context 'with an accounts receivable user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_receivable) } }

      it { is_expected.to(contain_exactly(other_receivable, receivable)) }
    end

    context 'with a carrier' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'with a broker user' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(be(false)) }
    end

    context 'with a root user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:root) } }

      it { is_expected.to(be(true)) }
    end

    context 'with another customer' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(be(false)) }
    end

    context 'with a carrier' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be(false)) }
    end

    context 'without a record' do
      let(:authorizable) { create(:customer_user) }
      let(:receivable) { nil }

      it { is_expected.to(be(false)) }
    end
  end
end
