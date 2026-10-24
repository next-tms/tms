# == Schema Information
#
# Table name: broker_countries
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return []
#
# Indexes
#
#  index_broker_countries_on_country_id  (country_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
require 'rails_helper'

RSpec.describe(BrokerCountry) do
  describe 'validations' do
    subject { described_class.new(country: create(:country)) }

    it { is_expected.to(validate_uniqueness_of(:country_id)) }
  end
end
