require 'rails_helper'

RSpec.describe Carrier, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:broker_carriers) }
    it { is_expected.to have_many(:carrier_areas) }
    it { is_expected.to have_many(:terminals) }
    it { is_expected.to have_many(:carrier_contacts) }
    it { is_expected.to have_many(:contacts).through(:carrier_contacts) }

    it { is_expected.to belong_to(:broker_billing_address).required(false) }
    it { is_expected.to belong_to(:check_mailing_address).required(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:scac).allow_nil }
  end
end
