require 'rails_helper'

RSpec.describe(ShipmentPolicy) do
  let(:policy) { described_class.new(record, authorizable:) }
  let(:record) { build(:shipment) }
  let(:contact_roles) { [] }
  let(:authorizable) { nil }

  before { contact_roles.each { |role| create(:contact_role, contact: authorizable.contact, role:) } }

  it_behaves_like 'authorized_attributable_policy'

  shared_examples_for 'manage access' do
    describe '#manage?' do
      subject { policy.apply(:manage?) }

      it { is_expected.to(be(true)) }
    end

    describe '#show?' do
      subject { policy.apply(:show?) }

      it { is_expected.to(be(true)) }
    end

    describe '#view?' do
      subject { policy.apply(:view?) }

      it { is_expected.to(be(true)) }
    end
  end

  shared_examples_for 'non-manage access' do
    describe '#manage?' do
      subject { policy.apply(:manage?) }

      it { is_expected.to(be(false)) }
    end
  end

  shared_examples_for 'party access' do
    describe '#party?' do
      subject { policy.apply(:party?) }

      it { is_expected.to(be(true)) }
    end

    describe '#view?' do
      subject { policy.apply(:view?) }

      it { is_expected.to(be(true)) }
    end
  end

  shared_examples_for 'non-party access' do
    describe '#party?' do
      subject { policy.apply(:party?) }

      it { is_expected.to(be(false)) }
    end
  end

  shared_examples_for 'view access' do
    describe '#show?' do
      subject { policy.apply(:show?) }

      it { is_expected.to(be(true)) }
    end
  end

  shared_examples_for 'no view access' do
    describe '#show?' do
      subject { policy.apply(:show?) }

      it { is_expected.to(be(false)) }
    end
  end

  context 'when broker?' do
    let(:authorizable) { create(:broker_user) }

    it_behaves_like 'non-manage access'
    it_behaves_like 'non-party access'
    it_behaves_like 'no view access'

    context 'when any_role?(:accounts_payable)' do
      let(:contact_roles) { %i[accounts_payable] }

      it_behaves_like 'non-manage access'
      it_behaves_like 'view access'
    end

    context 'when a sales rep for the customer' do
      before { create(:broker_customer_sales_rep, broker_customer: record.broker_customer, user: authorizable) }

      it_behaves_like 'non-manage access'
      it_behaves_like 'view access'
    end

    context 'when any_role?(:dispatch)' do
      let(:contact_roles) { %i[dispatch] }

      it_behaves_like 'manage access'
      it_behaves_like 'party access'
    end

    context 'when any_role?(:root)' do
      let(:contact_roles) { %i[root] }

      it_behaves_like 'manage access'
      it_behaves_like 'party access'
    end

    context 'when any_role?(:sales_rep_for_all_broker_customers)' do
      let(:contact_roles) { %i[sales_rep_for_all_broker_customers] }

      it_behaves_like 'manage access'
      it_behaves_like 'party access'
    end

    context 'when record.dispatcher == authorizable' do
      before { record.update!(dispatcher: authorizable) }

      it_behaves_like 'manage access'
      it_behaves_like 'party access'
    end
  end

  context 'when record is nil' do
    let(:authorizable) { create(:broker_user) }
    let(:record) { nil }

    it_behaves_like 'no view access'
  end

  context 'when customer?' do
    let(:authorizable) { create(:user, companyable: record.broker_customer) }

    it_behaves_like 'non-manage access'
    it_behaves_like 'non-party access'
    it_behaves_like 'view access'

    context 'when another customer' do
      let(:authorizable) { create(:user, companyable: create(:broker_customer)) }

      it_behaves_like 'non-manage access'
      it_behaves_like 'no view access'

      context 'when any_role?(:root)' do
        let(:contact_roles) { %i[root] }

        it_behaves_like 'non-manage access'
        it_behaves_like 'no view access'
      end
    end

    context 'when any_role?(:root)' do
      let(:contact_roles) { %i[root] }

      it_behaves_like 'manage access'
      it_behaves_like 'non-party access'
    end

    context 'when record.created_by == authorizable' do
      before { record.update!(created_by: authorizable) }

      it_behaves_like 'manage access'
      it_behaves_like 'party access'
    end
  end
end
