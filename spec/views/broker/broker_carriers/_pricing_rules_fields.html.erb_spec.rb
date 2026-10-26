require 'rails_helper'

RSpec.describe('broker/broker_carriers/_pricing_rules_fields') do
  subject { rendered }

  let(:broker_carrier) { pricing_rule.broker_carrier.reload }
  let(:partial) { 'broker/broker_carriers/pricing_rules_fields' }
  let(:pricing_rule) { create(:pricing_rule) }
  let(:template) { "<%= bootstrap_form_with(model: broker_carrier, url: '/') { |f| render(partial, f:) } %>" }

  before { render(inline: template, locals: { broker_carrier:, partial: }) }

  it { is_expected.to(have_select('broker_carrier[pricing_rules_attributes][0][from_area_id]', selected: 'California, US')) }
  it { is_expected.to(have_select('broker_carrier[pricing_rules_attributes][0][to_area_id]', selected: 'Texas, US')) }
  it { is_expected.to(include('name="broker_carrier[pricing_rules_attributes][NEW_RECORD][from_area_id]"')) }
end
