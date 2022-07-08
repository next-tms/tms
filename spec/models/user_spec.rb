require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:user_roles) }
    it { is_expected.to have_many(:commissions) }
    it { is_expected.to have_many(:problems) }
    it { is_expected.to have_many(:roles).through(:user_roles) }

    it { is_expected.to belong_to(:broker) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:broker_customer).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:time_zone_name) }
  end

  describe '#label' do
    subject { build(:user, first_name: "John", last_name: "Doe") }

    it { expect(subject.full_name).to eq('John Doe') }
  end

  describe '#dispatcher_for?' do
    let(:user) { create(:user) }
    let(:shipment) { create(:shipment) }

    context 'when shipment argument is nil' do
      it { expect(user.dispatcher_for?(nil)).to be_falsey }
    end

    context 'when user is the shipments dispatcher' do
      before { shipment.update(dispatcher: user) }

      it { expect(user.dispatcher_for?(shipment)).to be_truthy }
    end

    context 'when user is not shipments dispatcher but has a dispatch role' do
      before { user.user_roles.create(role: create(:role, name: 'dispatch')) }

      it { expect(user.dispatcher_for?(shipment)).to be_truthy }
    end
  end
end