require 'rails_helper'

RSpec.describe('shared/_companyable_select') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, name: 'Acme Freight')) }
  let(:user) { build(:carrier_user, companyable: broker_carrier.carrier) }

  before do
    broker_carrier
    render(partial: 'shared/companyable_select', locals: { f: BootstrapForm::FormBuilder.new(:user, user, view, {}) })
  end

  it { is_expected.to(have_select('Company', with_options: ['Acme Freight', 'Staff'])) }
  it { is_expected.to(have_select('Company', selected: 'Acme Freight')) }
end
