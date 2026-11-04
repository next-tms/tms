require 'rails_helper'
require Rails.root.join('db/migrate/20261103205832_move_broker_carrier_contacts_to_carriers')

RSpec.describe(MoveBrokerCarrierContactsToCarriers) do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:carrier) { broker_carrier.carrier }
  let(:contact_model) { described_class::Contact }
  let(:migrate) { ActiveRecord::Migration.suppress_messages { migration.up } }
  let(:migration) { described_class.new }
  let(:other_account) { create(:broker_carrier, carrier:) }
  let(:other_paired_user) { create(:broker_user) }
  let(:paired_user) { create(:broker_user) }
  let(:user) { create(:broker_user) }

  let!(:blank_email) { contact_model.create!(companyable_id: broker_carrier.id, companyable_type: 'BrokerCarrier', email: '') }
  let!(:kept) do
    contact_model.create!(comments: 'Rear', companyable_id: other_account.id, companyable_type: 'BrokerCarrier', email: 'DISPATCH@a.co')
  end
  let!(:merged) do
    contact_model.create!(comments: 'Gate 42', companyable_id: broker_carrier.id, companyable_type: 'BrokerCarrier', email: 'dispatch@a.co')
  end
  let!(:older_ops) { contact_model.create!(companyable_id: broker_carrier.id, companyable_type: 'BrokerCarrier', email: 'ops@a.co') }
  let!(:ops_on_carrier) do
    contact_model.create!(companyable_id: carrier.id, companyable_type: 'Carrier', email: 'OPS@a.co', work_phone: '555')
  end
  let!(:other_blank_email) { contact_model.create!(companyable_id: other_account.id, companyable_type: 'BrokerCarrier', email: '') }
  let!(:other_paired) { contact_model.create!(companyable_id: other_account.id, companyable_type: 'BrokerCarrier', email: 'pair@a.co') }
  let!(:paired) { contact_model.create!(companyable_id: broker_carrier.id, companyable_type: 'BrokerCarrier', email: 'pair@a.co') }
  let!(:unnamed) { contact_model.create!(companyable_id: other_account.id, companyable_type: 'BrokerCarrier', email: nil) }

  before do
    described_class::ContactRole.create!(contact_id: kept.id, role: 'dispatch')
    described_class::ContactRole.create!(contact_id: merged.id, role: 'claims')
    described_class::ContactRole.create!(contact_id: merged.id, role: 'dispatch')
    described_class::DocumentPreference.create!(contact_id: kept.id, kind: 'broker_bol')
    described_class::DocumentPreference.create!(contact_id: merged.id, kind: 'broker_bol')
    described_class::DocumentPreference.create!(contact_id: merged.id, kind: 'broker_label')
    described_class::DocumentPreference.create!(contact_id: merged.id, kind: 'broker_label')
    described_class::Subscription.create!(canceled_at: 1.day.ago, contact_id: kept.id, record_id: 1, record_type: 'Discussion')
    described_class::Subscription.create!(contact_id: merged.id, record_id: 1, record_type: 'Discussion')
    described_class::Subscription.create!(contact_id: merged.id, record_id: 2, record_type: 'Discussion')
    other_paired_user.update!(contact_id: other_paired.id)
    paired_user.update!(contact_id: paired.id)
    user.update!(contact_id: merged.id)
  end

  describe '#down' do
    it { expect { migration.down }.to(raise_error(ActiveRecord::IrreversibleMigration)) }
  end

  describe '#up' do
    let(:carrier_contacts) { contact_model.where(companyable_id: carrier.id, companyable_type: 'Carrier') }
    let(:kept_preferences) { described_class::DocumentPreference.where(contact_id: kept.id) }

    before { migrate }

    it { expect(contact_model.where(companyable_type: 'BrokerCarrier')).to(be_empty) }
    it { expect(contact_model.exists?(merged.id)).to(be(false)) }
    it { expect(carrier_contacts).to(contain_exactly(blank_email, kept, older_ops, other_blank_email, other_paired, paired, unnamed)) }
    it { expect(contact_model.find(kept.id).comments).to(eq("Rear\n\nGate 42")) }
    it { expect(contact_model.find(older_ops.id).work_phone).to(eq('555')) }
    it { expect(contact_model.exists?(ops_on_carrier.id)).to(be(false)) }
    it { expect(contact_model.where(id: [blank_email.id, other_blank_email.id]).pluck(:email)).to(eq([nil, nil])) }
    it { expect(contact_model.find(other_paired.id).email).to(eq('pair@a.co')) }
    it { expect(contact_model.find(paired.id).email).to(eq(paired_user.email)) }
    it { expect(paired_user.reload.contact_id).to(eq(paired.id)) }
    it { expect(described_class::ContactRole.where(contact_id: kept.id).pluck(:role)).to(contain_exactly('claims', 'dispatch')) }
    it { expect(kept_preferences.pluck(:kind)).to(contain_exactly('broker_bol', 'broker_label')) }
    it { expect(described_class::Subscription.where(contact_id: kept.id).pluck(:record_id)).to(contain_exactly(1, 2)) }
    it { expect(described_class::Subscription.where(contact_id: kept.id, record_id: 1).sole.canceled_at).to(be_nil) }
    it { expect(user.reload.contact_id).to(eq(kept.id)) }

    context "when the user's email is another contact's email" do
      let(:migrate) { nil }

      before { paired_user.update!(email: 'dispatch@a.co') }

      it { expect { migration.up }.to(raise_error(ActiveRecord::MigrationError, /share an email/)) }
    end
  end
end
