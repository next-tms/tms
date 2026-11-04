# == Schema Information
#
# Table name: users
#
# @!attribute id
#   @return [Integer]
# @!attribute companyable_type
#   @return [String]
# @!attribute confirmation_sent_at
#   @return [Time]
# @!attribute confirmation_token
#   @return [String]
# @!attribute confirmed_at
#   @return [Time]
# @!attribute current_sign_in_at
#   @return [Time]
# @!attribute current_sign_in_ip
#   @return [String]
# @!attribute deactivated
#   @return [Boolean]
# @!attribute email
#   @return [String]
# @!attribute email_notifications_blacklist
#   @return [String]
# @!attribute encrypted_password
#   @return [String]
# @!attribute failed_attempts
#   @return [Integer]
# @!attribute first_name
#   @return [String]
# @!attribute invitation_accepted_at
#   @return [Time]
# @!attribute invitation_created_at
#   @return [Time]
# @!attribute invitation_limit
#   @return [Integer]
# @!attribute invitation_sent_at
#   @return [Time]
# @!attribute invitation_token
#   @return [String]
# @!attribute invitations_count
#   @return [Integer]
# @!attribute last_name
#   @return [String]
# @!attribute last_sign_in_at
#   @return [Time]
# @!attribute last_sign_in_ip
#   @return [String]
# @!attribute locked_at
#   @return [Time]
# @!attribute phone
#   @return [String]
# @!attribute receive_email_notifications
#   @return [Boolean]
# @!attribute receive_notifications_from_self
#   @return [Boolean]
# @!attribute receive_read_notifications_by_email
#   @return [Boolean]
# @!attribute receive_sms_notifications
#   @return [Boolean]
# @!attribute remember_created_at
#   @return [Time]
# @!attribute reset_password_sent_at
#   @return [Time]
# @!attribute reset_password_token
#   @return [String]
# @!attribute sign_in_count
#   @return [Integer]
# @!attribute time_zone_name
#   @return [String]
# @!attribute unconfirmed_email
#   @return [String]
# @!attribute unlock_token
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute companyable_id
#   @return []
# @!attribute contact_id
#   @return []
# @!attribute invited_by_id
#   @return []
#
# Indexes
#
#  index_users_on_companyable           (companyable_type,companyable_id)
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_contact_id            (contact_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (invited_by_id => users.id)
#
require 'rails_helper'

RSpec.describe(User) do
  it_behaves_like 'has_companyable'

  describe 'relationships' do
    it { is_expected.to(have_many(:api_keys).dependent(:destroy)) }
    it { is_expected.to(have_many(:broker_customer_sales_reps).dependent(:destroy)) }
    it { is_expected.to(have_many(:commissions).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:problems).dependent(:nullify)) }
    it { is_expected.to(have_many(:shipments_as_dispatcher).dependent(:nullify)) }

    it { is_expected.to(belong_to(:companyable).optional) }
    it { is_expected.to(belong_to(:contact)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_presence_of(:time_zone_name)) }
  end

  describe '#validate_time_zone_name' do
    let(:record) { build(:broker_user, time_zone_name:) }
    let(:time_zone_name) { 'America/Denver' }

    before { record.valid? }

    it { expect(record.errors).not_to(include(:time_zone_name)) }

    context 'when time_zone_name does not resolve' do
      let(:time_zone_name) { 'not-a-zone' }

      it { expect(record.errors).to(include(:time_zone_name)) }
    end
  end

  describe '#set_time_zone_name' do
    let(:companyable) { nil }
    let(:record) { build(:user, companyable:, time_zone_name:) }
    let(:time_zone_name) { nil }

    before do
      create(:setting, key: 'time_zone_name', value: 'America/Chicago')
      record.valid?
    end

    it { expect(record.time_zone_name).to(eq('America/Chicago')) }

    context 'when companyable is a BrokerCustomer' do
      let(:companyable) { create(:broker_customer, office_address: create(:address, time_zone_name: 'America/Denver')) }

      it { expect(record.time_zone_name).to(eq('America/Denver')) }

      context 'when the office address time_zone_name is blank' do
        let(:companyable) { create(:broker_customer, office_address: create(:address, time_zone_name: nil)) }

        it { expect(record.time_zone_name).to(eq('America/Los_Angeles')) }
      end
    end

    context 'when time_zone_name is present' do
      let(:time_zone_name) { 'America/New_York' }

      it { expect(record.time_zone_name).to(eq('America/New_York')) }
    end
  end

  describe '#label' do
    let(:record) { build(:user, first_name: 'John', last_name: 'Doe') }

    it { expect(record.full_name).to(eq('John Doe')) }
  end

  describe '#dispatcher_for?' do
    let(:user) do
      record = build(:broker_user)
      record.save! && record
    end
    let(:shipment) { create(:shipment) }

    context 'when shipment argument is nil' do
      it { expect(user).not_to(be_dispatcher_for(nil)) }
    end

    context "when user is the shipment's dispatcher" do
      before { shipment.update(dispatcher: user) }

      it { expect(user).to(be_dispatcher_for(shipment)) }
    end

    context 'when user is not shipments dispatcher but has a dispatch role' do
      before { user.contact.contact_roles.create!(role: :dispatch) }

      it { expect(user).to(be_dispatcher_for(shipment)) }
    end
  end

  describe '#type' do
    let(:record) { build(:user) }

    it { expect(record.type).to(eq(:broker)) }

    context 'when companyable is a BrokerCustomer' do
      let(:broker_customer) { create(:broker_customer) }

      before { record.companyable = broker_customer }

      it { expect(record.type).to(eq(:customer)) }
    end
  end

  describe '#build_contact' do
    subject(:contact) { record.tap(&:build_contact).contact }

    let(:record) { build(:broker_user, contact: nil, email: 'Staff@Example.com') }

    it { is_expected.to(have_attributes(companyable: nil, email: 'staff@example.com')) }

    context 'when a staff contact already exists with the email' do
      before { create(:contact, companyable: nil, email: 'staff@example.com') }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#broker_customers' do
    let!(:broker_customer) { create(:broker_customer) }
    let(:record) { create(:broker_user) }

    before { record.add_role(:dispatch) }

    it { expect(record.broker_customers).to(include(broker_customer)) }

    context 'when customer?' do
      let(:record) { create(:customer_user) }

      it { expect(record.broker_customers).to(be_empty) }
    end
  end

  describe '#country_code' do
    let(:record) { build(:broker_user) }

    it { expect(record.country_code).to(eq('US')) }

    context 'when the mailing_address setting is in Canada' do
      let(:address) { create(:address, country_alpha2: 'CA', region_iso31662: 'CA-ON', zip_code: 'K1A 0B1') }

      before { create(:setting, key: 'mailing_address', value: address.id.to_s) }

      it { expect(record.country_code).to(eq('CA')) }
    end

    context 'when customer?' do
      let(:record) { build(:customer_user) }

      before { record.companyable.office_address.country_alpha2 = 'MX' }

      it { expect(record.country_code).to(eq('MX')) }
    end
  end

  describe '#coworkers' do
    let!(:coworker) { create(:broker_user) }
    let(:record) { create(:broker_user) }

    before { record.add_role(:root) }

    it { expect(record.coworkers).to(include(coworker, record)) }

    context 'when customer?' do
      let(:record) { create(:customer_user) }

      it { expect(record.coworkers).to(be_nil) }
    end
  end

  describe '#shipments' do
    let!(:shipment) { create(:shipment) }
    let(:record) { create(:broker_user) }

    before { record.add_role(:root) }

    it { expect(record.shipments).to(include(shipment)) }
  end

  describe '#update_contact' do
    let(:record) { create(:customer_user) }

    before { record.update!(companyable: nil) }

    it { expect(record.contact.reload.companyable).to(be_nil) }
  end
end
