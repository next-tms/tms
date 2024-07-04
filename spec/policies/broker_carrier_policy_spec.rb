require 'rails_helper'

RSpec.describe(BrokerCarrierPolicy) do
  let(:policy) { described_class.new(record, authorizable:) }
  let(:record) { build(:broker_carrier) }
  let(:contact_roles) { [] }
  let(:authorizable) { nil }

  before { contact_roles.each { |role| create(:contact_role, contact: authorizable.contact, role:) } }

  it_behaves_like 'authorized_attributable_policy'

  shared_examples_for 'manage access' do
    describe '#manage?' do
      subject { policy.apply(:manage?) }

      it { is_expected.to(be(true)) }
    end
  end

  shared_examples_for 'non-manage access' do
    describe '#manage?' do
      subject { policy.apply(:manage?) }

      it { is_expected.to(be(false)) }
    end
  end

  shared_examples_for 'view access' do
    describe '#view?' do
      subject { policy.apply(:view?) }

      it { is_expected.to(be(true)) }
    end
  end

  context 'when broker?' do
    let(:authorizable) { create(:user, companyable: record.broker) }

    it_behaves_like 'non-manage access'
    it_behaves_like 'view access'

    context 'when any_role?(:accounts_payable)' do
      let(:contact_roles) { %i[accounts_payable] }

      it_behaves_like 'manage access'
      it_behaves_like 'view access'
    end

    context 'when any_role?(:carrier_relations)' do
      let(:contact_roles) { %i[carrier_relations] }

      it_behaves_like 'manage access'
      it_behaves_like 'view access'
    end

    context 'when any_role?(:dispatch)' do
      let(:contact_roles) { %i[dispatch] }

      it_behaves_like 'non-manage access'
      it_behaves_like 'view access'
    end

    context 'when any_role?(:root)' do
      let(:contact_roles) { %i[root] }

      it_behaves_like 'manage access'
      it_behaves_like 'view access'
    end
  end

  context 'when customer?' do
    let(:authorizable) { create(:customer_user) }

    it_behaves_like 'non-manage access'
    it_behaves_like 'view access'
  end
end
