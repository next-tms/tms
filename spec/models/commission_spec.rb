# == Schema Information
#
# Table name: commissions
#
# @!attribute id
#   @return []
# @!attribute amount_cents
#   @return [Integer]
# @!attribute amount_currency
#   @return [String]
# @!attribute paid
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute shipment_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_commissions_on_shipment_id  (shipment_id)
#  index_commissions_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (user_id => users.id)
#
# @!attribute id
#   @return []
# @!attribute amount_cents
#   @return [Integer]
# @!attribute amount_currency
#   @return [String]
# @!attribute paid
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute shipment_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_commissions_on_shipment_id  (shipment_id)
#  index_commissions_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Commission do
  describe '#percent' do
    let(:commission) { described_class.new(amount: Money.new(500, 'USD'), shipment:) }
    let(:shipment) { Shipment.new(total_charges: Money.new(2_000, 'USD'), total_cost: Money.new(1_000, 'USD')) }

    it { expect(commission.percent).to(eq(0.5)) }

    context 'without profit' do
      before { shipment.total_cost = shipment.total_charges }

      it { expect(commission.percent).to(eq(0)) }
    end
  end
end
