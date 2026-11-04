require 'rails_helper'

RSpec.describe(CarriersHelper) do
  describe '#address_lines' do
    let(:address) { Transponder::ORM::CarrierAddress.new(id: 'hq', city: 'Austin', street: '<b>1 Main</b>') }

    it { expect(helper.address_lines(address)).to(eq('&lt;b&gt;1 Main&lt;/b&gt;<br>Austin')) }
    it { expect(helper.address_lines(address)).to(be_html_safe) }
  end

  describe '#carrier_user_status' do
    let(:invited) { build(:carrier_user, invitation_accepted_at: nil, invitation_sent_at: 1.day.ago) }

    it { expect(helper.carrier_user_status(build(:carrier_user))).to(eq('Active')) }
    it { expect(helper.carrier_user_status(build(:carrier_user, deactivated: true))).to(eq('Deactivated')) }
    it { expect(helper.carrier_user_status(invited)).to(eq('Invited')) }
    it { expect(helper.carrier_user_status(invited.tap { |user| user.deactivated = true })).to(eq('Deactivated')) }
  end
end
