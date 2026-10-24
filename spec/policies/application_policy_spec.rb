require 'rails_helper'

RSpec.describe(ApplicationPolicy) do
  let(:authorizable) { create(:broker_user) }
  let(:policy) { described_class.new(record, authorizable:) }
  let(:record) { Struct.new(:name).new('unrelated') }
  let(:roles) { [] }

  before { roles.each { |role| create(:contact_role, contact: authorizable.contact, role:) } }

  describe '#admin?' do
    subject { policy.apply(:admin?) }

    it { is_expected.to(be(false)) }

    context 'when root' do
      let(:roles) { %i[root] }

      it { is_expected.to(be(true)) }
    end

    context 'when a root customer' do
      let(:authorizable) { create(:customer_user) }
      let(:roles) { %i[root] }

      it { is_expected.to(be(false)) }

      context 'with a record of the customer' do
        let(:record) { Struct.new(:broker_customer).new(authorizable.companyable) }

        it { is_expected.to(be(true)) }
      end
    end
  end

  describe '#any_role?' do
    let(:roles) { %i[dispatch] }

    it { expect(policy.any_role?(:accounts_payable, :dispatch)).to(be(true)) }
    it { expect(policy.any_role?(:accounts_payable)).to(be(false)) }
  end

  describe '#broker?' do
    it { expect(policy.broker?).to(be(true)) }
    it { expect(described_class.new(record, authorizable: create(:customer_user)).broker?).to(be(false)) }
  end

  describe '#carrier?' do
    it { expect(policy.carrier?).to(be(false)) }
    it { expect(described_class.new(record, authorizable: create(:carrier_user)).carrier?).to(be(true)) }
  end

  describe '#customer?' do
    it { expect(policy.customer?).to(be(false)) }
    it { expect(described_class.new(record, authorizable: create(:customer_user)).customer?).to(be(true)) }
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    it { is_expected.to(be(false)) }

    context 'when the owner' do
      let(:authorizable) { create(:customer_user) }
      let(:record) { authorizable.companyable }

      it { is_expected.to(be(true)) }
    end

    context 'when a party' do
      let(:record) { Struct.new(:dispatch).new(authorizable) }
      let(:roles) { %i[dispatch] }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#owner?' do
    subject { policy.apply(:owner?) }

    it { is_expected.to(be(false)) }

    context 'when the record is the companyable' do
      let(:authorizable) { create(:customer_user) }
      let(:record) { authorizable.companyable }

      it { is_expected.to(be(true)) }
    end

    context 'when the record belongs to the companyable' do
      let(:authorizable) { create(:customer_user) }
      let(:record) { Struct.new(:broker_customer).new(authorizable.companyable) }

      it { is_expected.to(be(true)) }
    end

    context 'when the record was created by the authorizable' do
      let(:record) { Struct.new(:created_by).new(authorizable) }

      it { is_expected.to(be(true)) }
    end

    context 'when the record belongs to the authorizable' do
      let(:record) { Struct.new(:user).new(authorizable) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#party?' do
    subject { policy.apply(:party?) }

    let(:roles) { %i[dispatch] }

    it { is_expected.to(be(false)) }

    context 'when the record names the authorizable for a role' do
      let(:record) { Struct.new(:dispatch).new(authorizable) }

      it { is_expected.to(be(true)) }
    end

    context 'when the record lists the authorizable for a role' do
      let(:record) { Struct.new(:dispatches).new([ authorizable ]) }

      it { is_expected.to(be(true)) }
    end

    context 'when the role does not match' do
      let(:record) { Struct.new(:sales_rep).new(authorizable) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#show?' do
    let(:record) { Struct.new(:dispatch).new(authorizable) }
    let(:roles) { %i[dispatch] }

    it { expect(policy.apply(:show?)).to(be(true)) }
  end
end
