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
# @!attribute broker_id
#   @return [Integer]
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
    it { is_expected.to(have_many(:commissions)) }
    it { is_expected.to(have_many(:problems)) }

    it { is_expected.to(belong_to(:companyable)) }
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
    let(:companyable) { create(:broker) }
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
      record = build(:user, companyable: create(:broker))
      record.save! && record
    end
    let(:shipment) { create(:shipment) }

    context 'when shipment argument is nil' do
      it { expect(user).not_to(be_dispatcher_for(nil)) }
    end

    context "when user is the shipment's dispatcher" do
      before do
        user.update(companyable: shipment.broker)
        shipment.update(dispatcher: user)
      end

      it { expect(user).to(be_dispatcher_for(shipment)) }
    end

    context 'when user is not shipments dispatcher but has a dispatch role' do
      before { user.contact.contact_roles.create!(role: :dispatch) }

      it { expect(user).to(be_dispatcher_for(shipment)) }
    end
  end

  describe '#type' do
    let(:record) { build(:user) }

    it { expect(record.type).to(be_nil) }

    context 'when companyable is a Broker' do
      let(:broker) { create(:broker) }

      before { record.companyable = broker }

      it { expect(record.type).to(eq(:broker)) }
    end

    context 'when companyable is a BrokerCustomer' do
      let(:broker_customer) { create(:broker_customer) }

      before { record.companyable = broker_customer }

      it { expect(record.type).to(eq(:customer)) }
    end
  end
end
