# == Schema Information
#
# Table name: carriers
# Database name: primary
#
#  id                                  :integer          not null, primary key
#  acts_as_broker                      :boolean          default(FALSE)
#  consider_bol_and_pod_documents_same :boolean          default(FALSE)
#  encrypted_api_key                   :string
#  encrypted_proxy_url                 :string
#  has_traceable_pickup_confirmation   :boolean          default(FALSE)
#  mc_number                           :integer
#  name                                :string
#  scac                                :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  broker_billing_address_id           :bigint
#  check_mailing_address_id            :bigint
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
require 'rails_helper'

RSpec.describe(Carrier) do
  describe 'relationships' do
    it { is_expected.to(have_many(:broker_carriers)) }
    it { is_expected.to(have_many(:carrier_areas)) }
    it { is_expected.to(have_many(:terminals)) }

    it { is_expected.to(belong_to(:broker_billing_address).required(false)) }
    it { is_expected.to(belong_to(:check_mailing_address).required(false)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:scac).allow_nil) }

    it { is_expected.to(validate_uniqueness_of(:mc_number).allow_nil) }
  end
end
