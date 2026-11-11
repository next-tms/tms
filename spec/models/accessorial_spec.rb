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
