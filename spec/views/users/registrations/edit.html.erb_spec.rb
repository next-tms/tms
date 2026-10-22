require 'rails_helper'

RSpec.describe('users/registrations/edit') do
  let(:current_user) { build(:user, companyable: build(:broker_customer), time_zone_name: 'America/Denver') }

  before do
    allow(view).to(receive_messages(current_user:, resource: current_user))
    render
  end

  it { expect(rendered).to(include('<option selected="selected" value="America/Denver">')) }

  context 'when time_zone_name is not in the curated list' do
    let(:current_user) { build(:user, companyable: build(:broker_customer), time_zone_name: 'America/Boise') }

    it { expect(rendered).to(include('<option selected="selected" value="America/Boise">America/Boise</option>')) }
  end
end
