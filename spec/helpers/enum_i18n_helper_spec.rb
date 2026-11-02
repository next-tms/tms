require 'rails_helper'

RSpec.describe(EnumI18nHelper) do
  describe '#enum_l' do
    it { expect(helper.enum_l(PickupRequest.new, :reschedule_reason)).to(be_nil) }
    it { expect(helper.enum_l(PickupRequest.new(reschedule_reason: 'weather'), :reschedule_reason)).to(eq('Weather')) }
  end
end
