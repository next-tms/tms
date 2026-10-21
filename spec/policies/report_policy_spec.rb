require 'rails_helper'

RSpec.describe(ReportPolicy) do
  let(:authorizable) { create(:broker_user, companyable: report.broker) }
  let(:contact_roles) { %i[dispatch] }
  let(:policy) { described_class.new(record, authorizable:) }
  let(:record) { report }
  let(:report) { create(:report) }

  before { contact_roles.each { |role| create(:contact_role, contact: authorizable.contact, role:) } }

  shared_examples_for 'allowed' do |*rules|
    rules.each do |rule|
      it { expect(policy.apply(rule)).to(be(true)) }
    end
  end

  shared_examples_for 'denied' do |*rules|
    rules.each do |rule|
      it { expect(policy.apply(rule)).to(be(false)) }
    end
  end

  it_behaves_like 'allowed', :create?, :index?, :new?, :show?, :view?
  it_behaves_like 'denied', :destroy?, :edit?, :manage?, :update?

  context 'when the creator' do
    let(:authorizable) { report.created_by }

    it_behaves_like 'allowed', :destroy?, :edit?, :manage?, :update?
  end

  context 'when root' do
    let(:contact_roles) { %i[root] }

    it_behaves_like 'allowed', :destroy?, :edit?, :manage?, :update?
  end

  context 'when accounts receivable' do
    let(:contact_roles) { %i[accounts_receivable] }

    it_behaves_like 'allowed', :index?, :show?
  end

  context 'when a sales rep' do
    let(:contact_roles) { %i[sales_rep] }

    it_behaves_like 'allowed', :index?, :show?
  end

  context 'without a reporting role' do
    let(:contact_roles) { %i[carrier_relations] }

    it_behaves_like 'denied', :create?, :index?, :show?
  end

  context 'when another broker' do
    let(:authorizable) { create(:broker_user) }

    it_behaves_like 'allowed', :index?
    it_behaves_like 'denied', :destroy?, :edit?, :show?, :update?
  end

  context 'when a customer' do
    let(:authorizable) { create(:customer_user) }
    let(:contact_roles) { %i[root] }

    it_behaves_like 'denied', :create?, :index?, :show?
  end

  context 'when a preset' do
    let(:authorizable) { create(:broker_user) }
    let(:contact_roles) { %i[root] }
    let(:record) { Report::Preset.find('freight-report') }

    it_behaves_like 'allowed', :show?
    it_behaves_like 'denied', :destroy?, :edit?, :update?
  end
end
