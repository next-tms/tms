require 'rails_helper'

RSpec.describe('broker/carriers/broker_carriers/_pricing_rules_fields') do
  subject { rendered }

  let(:broker_carrier) { pricing_rule.broker_carrier.reload }
  let(:field_name) { 'broker_carrier[pricing_rules_attributes][0][lane_id]' }
  let(:partial) { 'broker/carriers/broker_carriers/pricing_rules_fields' }
  let(:pricing_rule) { create(:pricing_rule) }
  let(:template) { "<%= bootstrap_form_with(model: broker_carrier, url: '/') { |f| render(partial, f:) } %>" }

  before { render(inline: template, locals: { broker_carrier:, partial: }) } # rubocop:disable Rails/RenderInline

  it { is_expected.to(have_select(field_name, selected: 'CA, US → TX, US')) }
  it { is_expected.to(have_select(field_name, with_options: ['CA, US → TX, US', 'US → AZ, US (850, 851)'])) }

  it { is_expected.to(include('name="broker_carrier[pricing_rules_attributes][NEW_RECORD][lane_id]"')) }
end
