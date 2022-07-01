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
end