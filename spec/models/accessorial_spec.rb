# == Schema Information
#
# Table name: accessorials
#
# @!attribute id
#   @return []
# @!attribute code
#   @return [String]
# @!attribute fee
#   @return [Boolean]
# @!attribute freight_kit_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_accessorials_on_name  (name) UNIQUE
#
require 'rails_helper'

RSpec.describe(Accessorial) do
  describe '#create_broker_accessorials' do
    let!(:record) { create(:accessorial) }

    it { expect(BrokerAccessorial.where(accessorial: record).count).to(eq(1)) }

    it do
      expect(BrokerAccessorial.find_by(accessorial: record)).to(have_attributes(broker_only: false, code: record.code, name: record.name))
    end
  end
end
